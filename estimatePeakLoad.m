function peak = estimatePeakLoad(arriveTime, departTime, consump, chargingPower)

    timeRange=max(departTime)-min(arriveTime);
    chargingarray = zeros(length(arriveTime), timeRange);

    for i=1:length(arriveTime)
        endCharge = ceil(consump(i)/chargingPower);
        idx = arriveTime(i)-min(arriveTime)+1;
        chargingarray(i, idx:idx + endCharge) = 1;
    end
    peak = max(sum(chargingarray)*chargingPower);
end