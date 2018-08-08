function chargingLoad = estiamteControlledCharging(load, limit, demand, ...
    chargingPower)
% Estimate the controled charging load such that the total load does not exceed
% the limit. The charging power is reduced and charging time is extended.
% Make sure that the units of time and energy match.
% Example
% --------
% >> load = [10, 20, 30, 10, 10]; limit = 40; demand = 65; ...
%    chargingPower = 25; 
% >> estiamteControlledCharging(load, limit, demand,chargingPower)
% >> [25, 20, 10, 10, 0]

    chargingLoad = zeros(length(load),1);
    availablePower = limit-load;
    
    i = 1;
    while(demand > 0 && i <= length(load)) % quit at the end of the load vector
        chargingLoad(i) = min([chargingPower, availablePower(i), demand]);
        demand = demand-chargingLoad(i);
        i = i+1;
    end
end