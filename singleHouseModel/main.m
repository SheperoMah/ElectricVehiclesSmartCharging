% Author := Mahmoud Shepero
% Date := 7 August 2018

rng(5);
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
chargingPower = 3700; % W
powerLimit = 5000; % peak limit
load = data(:,10); % load data


durDumb = zeros(length(dateDays),1);
durControlled = zeros(length(dateDays),1);
chargingLoadDumb = zeros(length(data),1);
chargingLoadControlled = zeros(length(data),1);


for i=1:length(dateDays)
    
    if isweekend(dateDays(i))
        [arrivalTime, energyReq] = sampleCarTrip(weekendData.distance, ...
            weekendData.arrival, specificConsumption, 1);
    else
        [arrivalTime, energyReq] = sampleCarTrip(weekdayData.distance, ...
            weekdayData.arrival, specificConsumption, 1);
    end
    
    durDumb(i) = estimateOpportunisticCharging(energyReq*timeUnitConversion, ...
        chargingPower);
    
    arrivalMin = (i-1) * 1440 + 1 + arrivalTime;
    endDumbcharging = min(arrivalMin+durDumb(i)-1, length(chargingLoadDumb));
    chargingLoadDumb( arrivalMin:endDumbcharging ) = chargingPower;
    
    
    chargingLoad = estiamteControlledCharging(load(arrivalMin:end) + ...
        chargingLoadControlled(arrivalMin:end), ... 
    powerLimit, energyReq*timeUnitConversion, chargingPower);
    
    durControlled(i) = length(chargingLoad(chargingLoad>0));
        
    

    chargingLoadControlled(arrivalMin:end) = chargingLoadControlled( ...
        arrivalMin:end) + chargingLoad;
    
    
    
end


%%

figure
plot(load+chargingLoadDumb); hold on;plot(load+chargingLoadControlled)

figure
plot(durDumb); hold on; plot(durControlled)

figure
histogram(durControlled-durDumb)

