% Author := Mahmoud Shepero
% Date := 7 August 2018


%% LOAD THE DATA FILE
data = importdata('HouseholdLoad.txt');

data = data';


load('../../EVSpatialModel/weekdayandweekendMonteCarlo.mat')
clearvars T Filenames
%% CORRECT THE DATA TO COMBINE ALL TRIPS ARRIVING HOME

weekdayData = combineNonResidentialTrips(Weekday);

weekendData = combineNonResidentialTrips(Weekend);


%% STUDY THE EFFECT OF SMART CHARGING GIVEN THE FUSE-SIZES OF VATTENFALL

date1 = datetime(2018, 1, 1, 0, 0, 0);
date2 = datetime(2018, 12, 31, 0, 0, 0);
dateDays = (date1:days(1):date2)';

specificConsumption = 250; % Wh/km
timeUnitConversion = 60; % convert from Wh to Wmin
chargingPower = [3700, 6900, 7300, 11000, 22000]; % W
powerLimit = [11000, 14000, 17000, 24000, 35000, 44000]; % peak limit from Vattenfall

controlled = struct();
controlled.maxDurationExtension = zeros(length(chargingPower), length(powerLimit), size(data,2));
controlled.durationExtension = zeros(length(chargingPower), length(powerLimit), ...
    size(data,2), length(dateDays));
controlled.countDurationExtension = zeros(length(chargingPower), length(powerLimit),...
    size(data,2));
controlled.reducedPeak = zeros(length(chargingPower), length(powerLimit), size(data,2));

structure = struct('durDumb', [], ...
                'chargingLoadDumb', [], ...
                'totalLoadDumb', [], ...
                'durControlled', [], ...
                'chargingLoadControlled', [], ...
                'totalLoadControlled', [], ...
                'durValley', [], ...
                'chargingLoadValley', [], ...
                'totalLoadValley', []);
            
valley = struct();
valley.maxDurationExtension = zeros(length(chargingPower), length(powerLimit), ...
    size(data,2));
valley.maxDurationReduction = zeros(length(chargingPower), length(powerLimit), ...
    size(data,2));
valley.minDurationReduction = zeros(length(chargingPower), length(powerLimit), ...
    size(data,2));
valley.durationExtension = zeros(length(chargingPower), length(powerLimit), ...
    size(data,2), length(dateDays));
valley.countDurationExtension = zeros(length(chargingPower), length(powerLimit),...
    size(data,2));
valley.countDurationReduction = zeros(length(chargingPower), length(powerLimit),...
    size(data,2));

M = feature('numcores');
idx = [];
for home = 1:size(data,2)
    for lim = 1:length(powerLimit)
        for cp = 1:length(chargingPower)
            idx(end+1,:) = [chargingPower(cp), powerLimit(lim), home];
            rng(5);
            if chargingPower(cp) >= powerLimit(lim)
                % do not do the study
            structure(end+1) = struct('durDumb', nan, ...
                'chargingLoadDumb', nan, ...
                'totalLoadDumb', nan, ...
                'durControlled', nan, ...
                'chargingLoadControlled', nan, ...
                'totalLoadControlled', nan, ...
                'durValley', nan, ...
                'chargingLoadValley', nan, ...
                'totalLoadValley', nan); 
            else
            tempStruct = compareChargingMethods(data(:,home), powerLimit(lim), ...
                chargingPower(cp), specificConsumption, timeUnitConversion, ...
                dateDays, weekdayData, weekendData);
            structure(end+1) = tempStruct;
            end
            
            
            %collect controlled charging stats
            controlled.maxDurationExtension(cp,lim,home) =  max( ...
                structure(end).durControlled - structure(end).durDumb);
            
            controlled.durationExtension(cp, lim, home, :) = max(structure(end).durControlled - ...
                structure(end).durDumb,0);
            
            controlled.countDurationExtension(cp,lim, home) = sum((structure(end).durControlled - ...
                structure(end).durDumb) > 0);
            
            controlled.reducedPeak(cp,lim,home) = max(max(structure(end).totalLoadDumb)...
                - max(structure(end).totalLoadControlled),0); 
            % remove the approximation effect of dumb charging
            
            
            %collect valley filling stats
            deltaReducedTime = structure(end).durDumb - structure(end).durValley;
            % +ve when valley charging is faster (reduction)
            valley.maxDurationExtension(cp,lim,home) =  min( ...
                [deltaReducedTime(deltaReducedTime < 0);0]);
            
            valley.maxDurationReduction(cp,lim,home) =  max( ...
                [deltaReducedTime(deltaReducedTime > 0);0]);
            
            reductions = deltaReducedTime(deltaReducedTime > 0);
            if isempty(reductions)
                valley.minDurationReduction(cp,lim,home) = 0;
            else
                valley.minDurationReduction(cp,lim,home) =  min( ...
                reductions);
            end
            valley.durationExtension(cp, lim, home, :) = -deltaReducedTime;
            
            valley.countDurationExtension(cp,lim, home) = sum( ...
                deltaReducedTime < 0);
            
            valley.countDurationReduction(cp,lim, home) = sum(...
                deltaReducedTime > 0);
            
        end
    end
end

structure = structure(2:end);

idxCancelledExperiments = chargingPower' * ones(1,length(powerLimit)) >=...
    ones(length(chargingPower), 1) * powerLimit;
% estimate the controlled charging average extension
temp = reshape(controlled.durationExtension, ...
    length(chargingPower), length(powerLimit), []);
controlled.averageDurationExtension = sum(temp,3)./sum(temp>0,3);
controlled.averageDurationExtension(isnan(...
    controlled.averageDurationExtension)) = 0;
controlled.averageDurationExtension(idxCancelledExperiments) = nan;

%estimate the valley charging average extension
temp = reshape(valley.durationExtension, ...
    length(chargingPower), length(powerLimit), []);
valley.averageDurationExtension = sum(temp,3)./sum(temp>0,3);
valley.averageDurationExtension(isnan(valley.averageDurationExtension)) = 0;
valley.averageDurationExtension(idxCancelledExperiments) = nan;

clearvars temp M cp lim home temp
%%
s = controlled;
resultsControl.avgCountExtension = mean(s.countDurationExtension,3);
resultsControl.maxCountExtension = max(s.countDurationExtension,[],3);
resultsControl.avgDurExt = ceil(s.averageDurationExtension);
resultsControl.maxDurExt = max(s.maxDurationExtension,[],3);
flds = fieldnames(resultsControl);
for i=1:numel(flds)
    resultsControl.(flds{i})(idxCancelledExperiments) = nan;
end

save('resultsControlled.mat', 'resultsControl');

%%
s = valley;
resultsValley.minCountReduc = min(s.countDurationReduction,[],3);
resultsValley.maxCountExt = max(s.countDurationExtension,[],3);

temp = reshape(s.durationExtension, ...
    length(chargingPower), length(powerLimit), []);
resultsValley.avgDurationReduc = -sum(temp.*(temp<0),3)./sum(temp < 0,3);
resultsValley.minDurationReduc = min(s.maxDurationReduction,[],3);
resultsValley.maxDurationExt = max(-s.maxDurationExtension,[],3);

flds = fieldnames(resultsValley);
for i=1:numel(flds)
    resultsValley.(flds{i})(idxCancelledExperiments) = nan;
end

save('resultsValley.mat', 'resultsValley');
%%


s = controlled;
xvalues = categorical(chargingPower/1000);
yvalues = flip(categorical(powerLimit/1000));

figure
subplot(2,2,1)
dataPlot = mean(s.countDurationExtension,3);
dataPlot(idxCancelledExperiments) = nan;
h = heatmap(xvalues, yvalues,flipud(dataPlot'));
h.XLabel = 'Charging Power (kW)';
h.YLabel = 'Fuse size (kW)';
h.ColorbarVisible = 'off';
 
subplot(2,2,2)
dataPlot = max(s.countDurationExtension,[],3);
dataPlot(idxCancelledExperiments) = nan;
h = heatmap(xvalues, yvalues,flipud(dataPlot'));
h.XLabel = 'Charging Power (kW)';
h.YLabel = 'Fuse size (kW)';
h.ColorbarVisible = 'off';

subplot(2,2,3)
dataPlot = ceil(s.averageDurationExtension);
dataPlot(idxCancelledExperiments) = nan;
h = heatmap(xvalues, yvalues,flipud(dataPlot'));
h.XLabel = 'Charging Power (kW)';
h.YLabel = 'Fuse size (kW)';
h.ColorbarVisible = 'off';

subplot(2,2,4)
dataPlot = max(s.maxDurationExtension,[],3);
dataPlot(idxCancelledExperiments) = nan;
clabel = arrayfun(@(x){[sprintf('%02d',floor(x/60)), ...
    ':', sprintf('%02d',mod(x,60))]}, dataPlot);
h = heatmap(xvalues, yvalues,flipud(dataPlot'));
h.XLabel = 'Charging Power (kW)';
h.YLabel = 'Fuse size (kW)';
h.ColorbarVisible = 'off';

%%

s = valley;
xvalues = categorical(chargingPower/1000);
yvalues = flip(categorical(powerLimit/1000));

figure
subplot(2,2,1)
dataPlot = max(-s.maxDurationExtension,[],3); %%max(reshape(s.durationExtension,5,6,[]),[],3);
dataPlot(idxCancelledExperiments) = nan;
h = heatmap(xvalues, yvalues,flipud(dataPlot'));
h.XLabel = 'Charging Power (kW)';
h.YLabel = 'Fuse size (kW)';
h.ColorbarVisible = 'off';
 
subplot(2,2,2)
dataPlot = min(s.maxDurationReduction,[],3);
dataPlot(idxCancelledExperiments) = nan;
h = heatmap(xvalues, yvalues,flipud(dataPlot'));
h.XLabel = 'Charging Power (kW)';
h.YLabel = 'Fuse size (kW)';
h.ColorbarVisible = 'off';

subplot(2,2,3)
dataPlot = max(s.countDurationExtension,[],3);
dataPlot(idxCancelledExperiments) = nan;
h = heatmap(xvalues, yvalues,flipud(dataPlot'));
h.XLabel = 'Charging Power (kW)';
h.YLabel = 'Fuse size (kW)';
h.ColorbarVisible = 'off';

subplot(2,2,4)
dataPlot = min(s.countDurationReduction,[],3);
dataPlot(idxCancelledExperiments) = nan;
h = heatmap(xvalues, yvalues,flipud(dataPlot'));
h.XLabel = 'Charging Power (kW)';
h.YLabel = 'Fuse size (kW)';
h.ColorbarVisible = 'off';

%% PLOT THE WEEKDAY AND WEEKEND ARRIVAL TIMES
[fweekday,xiweekday] = ksdensity(weekdayData.arrival);
[fweekend,xiweekend] = ksdensity(weekendData.arrival);


f = figure;
histogram(weekdayData.arrival, 'Normalization', 'pdf', ...
    'FaceColor',[0 178 127]/255)
hold on;
histogram(weekendData.arrival, 'Normalization', 'pdf', ...
    'FaceColor',[255 122 84]/255)
xlim([0,1440])
xticks([0, 360, 720, 1080, 1440])
xticklabels({'00:00', '06:00', '12:00', '18:00', '00:00'})
xlabel('Arrival time')
ylabel('Probability')
plot(xiweekday,fweekday, 'linewidth', 1.8, ...
    'color', [0 120 92]/255)
plot(xiweekend,fweekend, 'linewidth', 1.8, ...
    'color', [178 39 0]/255)
legend({'Weeday', 'Weekend', 'KDE Weekday', 'KDE Weekend'}...
    , 'location', 'NorthWest')
set(gca, 'fontsize', 20)
box off

%f.PaperUnits = 'centimeters';
%f.PaperPosition = [0 0 30 20];
set(f,'Units','Inches');
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto', ...
    'PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
print('ArrivalTime','-dpdf','-r0')


%% PLOT DIFFERENT CHARGING METHODS

data = importdata('HouseholdLoad.txt');

data = data';
loadSample = mean(reshape(sum(data,2),1440,[]),2);
load = [loadSample;loadSample;loadSample];
str = struct();
str.arrival = [1080; 1200];
str.distance = [75; 100];
structure = compareChargingMethods(load, 11000, ...
                6900, 250, 60, ...
                [datetime(2018,1,1), datetime(2018,1,2), ...
                datetime(2018,1,3)], str, str);

%%

f = figure;
angl = 90;

subplot(1,3,1)
area(load(1:2880)/1000 + structure.chargingLoadDumb(1:2880)/1000);
hold on;
area(load(1:2880)/1000)
plot(1:2880, ones(2880,1)*11,'linewidth',2)
ylabel('Power (kW)')
xlabel('Time')
title('(a)')
xlim([0 2880])
ylim([0 max(load(1:2880)/1000 + structure.chargingLoadDumb(1:2880)/1000 + 0.5)])
xticks([0, 720, 1440,  2160, 2880]);
xticklabels({'00:00', '12:00', '00:00', '12:00', '00:00'})
ax = gca;
ax.XTickLabelRotation = angl;
set(gca, 'fontsize', 20)
box off

subplot(1,3,2)
area(load(1:2880)/1000 + structure.chargingLoadControlled(1:2880)/1000);
hold on;
area(load(1:2880)/1000)
plot(1:2880, ones(2880,1)*11,'linewidth',2)
xlim([0 2880])
ylim([0 max(load(1:2880)/1000 + structure.chargingLoadDumb(1:2880)/1000 + 0.5)])
ylabel('Power (kW)')
xlabel('Time')
xticks([0, 720, 1440,  2160, 2880]);
xticklabels({'00:00', '12:00', '00:00', '12:00', '00:00'})
ax = gca;
ax.XTickLabelRotation = angl;
title('(b)')
set(gca, 'fontsize', 20)
box off


subplot(1,3,3)
area(load(1:2880)/1000 + structure.chargingLoadValley(1:2880)/1000);
hold on;
title('(c)')
area(load(1:2880)/1000)
plot(1:2880, ones(2880,1)*11,'linewidth',2)
xlim([0 2880])
ylim([0 max(load(1:2880)/1000 + structure.chargingLoadDumb(1:2880)/1000 + 0.5)])
ylabel('Power (kW)')
xlabel('Time')
xticks([0, 720, 1440,  2160, 2880]);
xticklabels({'00:00', '12:00', '00:00', '12:00', '00:00'})
ax = gca;
ax.XTickLabelRotation = angl;
set(gca, 'fontsize', 20)
box off

wdth = 10;
height = 10*6/8;
set(f,'Resize','off');
set(f,'PaperUnits','Inches');
set(f,'PaperPositionMode','manual');
set(f,'PaperPosition',[0 0 wdth height]);
set(f,'PaperSize',[wdth height]); % IEEE columnwidth = 9cm

print('ChargingSchemes','-dpdf','-r0')

%%
CpPlot = [3700, 6900, 7300, 11000];
size = ['+', 'o', '*', 'x'];
FuseSizePlot = [14000];
ii = ismember(idx(:,1),CpPlot) & ismember(idx(:,2), FuseSizePlot);
for i =1:length(ii)
    if ii(i) == 1 
        idxCp = find(CpPlot == idx(i,1));
        scatter(1:365,-(structure(i).durDumb-structure(i).durControlled),...
            [],size(idxCp)); 
        hold on; 
    end
end

