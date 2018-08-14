function struct = compareChargingMethods(load, powerLimit, ...
    chargingPower, specificConsumption, timeUnitConversion,  ...
   dateDays, weekdayData, weekendData)
% load: the load vector
% powerLimit: the limit of controlled charging load
% chargingPower: maximum charging power
% specificConsumption: consumption of EVs, e.g. 250Wh/km
% timeUnitConversion: to convert between units of time in the load and ...
% in the specificConsumption, e.g., 60 means that specificConsumption is in
% Wh and the load is per minute.
% dateDays: days vector to estimate weekdays and weekends
% weekdayData: mobility data on weekday
% weekendData: mobility data on weekend


durDumb = zeros(length(dateDays),1);
durControlled = zeros(length(dateDays),1);
durValleyFilling = zeros(length(dateDays),1);
chargingLoadDumb = zeros(length(load),1);
chargingLoadControlled = zeros(length(load),1);
chargingLoadValleyFilling = zeros(length(load),1);
for i=1:length(dateDays)
    
    if isweekend(dateDays(i))
        [arrivalTime, energyReq] = sampleCarTrip(weekendData.distance, ...
            weekendData.arrival, specificConsumption, 1);
    else
        [arrivalTime, energyReq] = sampleCarTrip(weekdayData.distance, ...
            weekdayData.arrival, specificConsumption, 1);
    end
    % Dumb charging 
    durDumb(i) = estimateOpportunisticCharging(energyReq*timeUnitConversion*2, ...
        chargingPower); % multiply by two to estimate round-trip
    
    arrivalMin = (i-1) * 1440 + arrivalTime;
    endDumbcharging = min(arrivalMin+durDumb(i), length(chargingLoadDumb));
    chargingLoadDumb( arrivalMin:endDumbcharging ) = chargingPower;
    
    % Controlled charing
    totalLoad = load(arrivalMin:end) + chargingLoadControlled(arrivalMin:end);
    [chargingLoad,durControlled(i)] = performControlledCharging(...
    totalLoad, powerLimit, energyReq*timeUnitConversion*2, chargingPower, ...
    i == length(dateDays), durDumb(i));
    % multiply by two to estimate round-trip
    
    chargingLoadControlled(arrivalMin:end) = chargingLoadControlled( ...
        arrivalMin:end) + chargingLoad;
    
    
     % ValleyFilling charing
    totalLoad = load(arrivalMin:end) + chargingLoadValleyFilling(arrivalMin:end);
    cpValley = Inf;
    [chargingLoadVall, durValleyFilling(i)] = performControlledCharging(...
    totalLoad, powerLimit, energyReq*timeUnitConversion*2, cpValley, ...
    i == length(dateDays), durDumb(i));
    % multiply by two to estimate round-trip
    
    chargingLoadValleyFilling(arrivalMin:end) = chargingLoadValleyFilling( ...
        arrivalMin:end) + chargingLoadVall;
    
    
end


struct.durDumb = durDumb;
struct.chargingLoadDumb = chargingLoadDumb;
struct.totalLoadDumb = chargingLoadDumb + load;
struct.durControlled = durControlled;
struct.chargingLoadControlled = chargingLoadControlled;
struct.totalLoadControlled = chargingLoadControlled + load;
struct.durValley = durValleyFilling;
struct.chargingLoadValley = chargingLoadValleyFilling;
struct.totalLoadValley = chargingLoadValleyFilling + load;

end

function [chargingLoad,durControlled] = performControlledCharging(...
    totalLoad, powerLimit, energyReq, cp, i, durDumb)

    chargingLoad = estiamteControlledCharging(totalLoad , ... 
    powerLimit, energyReq, cp); 
    % multiply by two to estimate round-trip
    
    durControlled = length(chargingLoad(chargingLoad>0));
    
    if (i == 1 && durControlled < durDumb)
       warning(['Smart charging duration extends after the end ' ...
           'of the load timeseries. The duration is truncated.']); 
       durControlled = durDumb;
    end
    

end