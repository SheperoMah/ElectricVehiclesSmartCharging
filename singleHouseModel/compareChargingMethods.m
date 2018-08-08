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
chargingLoadDumb = zeros(length(load),1);
chargingLoadControlled = zeros(length(load),1);


for i=1:length(dateDays)
    
    if isweekend(dateDays(i))
        [arrivalTime, energyReq] = sampleCarTrip(weekendData.distance, ...
            weekendData.arrival, specificConsumption, 1);
    else
        [arrivalTime, energyReq] = sampleCarTrip(weekdayData.distance, ...
            weekdayData.arrival, specificConsumption, 1);
    end
    
    durDumb(i) = estimateOpportunisticCharging(energyReq*timeUnitConversion*2, ...
        chargingPower); % multiply by two to estimate round-trip
    
    arrivalMin = (i-1) * 1440 + 1 + arrivalTime;
    endDumbcharging = min(arrivalMin+durDumb(i)-1, length(chargingLoadDumb));
    chargingLoadDumb( arrivalMin:endDumbcharging ) = chargingPower;
    
    
    chargingLoad = estiamteControlledCharging(load(arrivalMin:end) + ...
        chargingLoadControlled(arrivalMin:end), ... 
    powerLimit, energyReq*timeUnitConversion*2, chargingPower); 
    % multiply by two to estimate round-trip
    
    durControlled(i) = length(chargingLoad(chargingLoad>0));
    
    if (i == length(dateDays) && durControlled(i) < durDumb(i))
       warning(['Smart charging duration extends after the end ' ...
           'of the load timeseries. The duration is truncated.']); 
       durControlled(i) = durDumb(i);
    end
    

    chargingLoadControlled(arrivalMin:end) = chargingLoadControlled( ...
        arrivalMin:end) + chargingLoad;
    
    
    
end


struct.durDumb = durDumb;
struct.chargingLoadDumb = chargingLoadDumb;
struct.totalLoadDumb = chargingLoadDumb + load;
struct.durControlled = durControlled;
struct.chargingLoadControlled = chargingLoadControlled;
struct.totalLoadControlled = chargingLoadControlled + load;
end