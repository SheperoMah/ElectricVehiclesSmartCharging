% Author := Mahmoud Shepero
% Date := 7 August 2018


%% LOAD THE DATA FILE
data = importdata('HouseholdLoad.txt');

data = data';

load('../../EVSpatialModel/weekdayandweekendMonteCarlo.mat')
clearvars T fileNames
%% CORRECT THE DATA TO COMBINE ALL TRIPS ARRIVING HOME

weekdayData = combineNonResidentialTrips(Weekday);

weekendData = combineNonResidentialTrips(Weekend);


%% 
date1 = datetime(2018, 1, 1, 0, 0, 0);
date2 = datetime(2018, 12, 31, 0, 0, 0);
dateDays = (date1:days(1):date2)';

specificConsumption = 250; % Wh/km
timeUnitConversion = 60; % convert from Wh to Wmin
chargingPower = [3700, 6900, 7300, 11000, 22000]; % W
powerLimit = [11000, 14000, 17000, 24000, 35000, 44000]; % peak limit


maxDurationExtenstion = zeros(length(chargingPower), length(lim), length(home));
countDurationExtenstion = zeros(length(chargingPower), length(lim), length(home));
reducedPeak = zeros(length(chargingPower), length(lim), length(home));


rng(5);
for cp = 1:length(chargingPower)
    for lim = 1:length(powerLimit)
        for home = 1:size(data,2)
            struct = compareChargingMethods(data(:,home), powerLimit(lim), ...
                chargingPower(cp), timeUnitConversion, specificConsumption, ...
                dateDays, weekdayData, weekendData);
            
            maxDurationExtenstion(cp,lim,home) =  max( ...
                struct.durControlled - struct.durDumb);
            
            countDurationExtenstion(cp,lim, home) = sum((struct.durControlled - ...
                struct.durDumb) > 0 );
            
            reducedPeak(cp,lim,home) = max(struct.totalLoadDumb)...
                - max(struct.totalLoadControlled);
        end
    end
end
%%



