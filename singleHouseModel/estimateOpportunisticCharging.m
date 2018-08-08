function dur = estimateOpportunisticCharging(demand, chargingPower)
% Estimate the time to charge an EV. Make sure that the units of time and
% energy match.
% Example
% --------
% estimateOpportunisticCharging(3700*60, 3700)
% >> 60
% estimateOpportunisticCharging(100*1000*60, 120*1000)
% >> 50
    dur = ceil(demand/chargingPower);
 
end