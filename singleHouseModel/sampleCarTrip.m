function [arrivTime, energyReq] =  sampleCarTrip(distances, arrivalTimes, ... 
    energyConsumption, numEVs)

    arrivTime = randsample(arrivalTimes,numEVs, true);
    energyReq = randsample(distances, numEVs, true)*energyConsumption;

end