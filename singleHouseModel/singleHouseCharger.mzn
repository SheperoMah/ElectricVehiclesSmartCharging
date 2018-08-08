include "globals.mzn";
include "../AtriumLjunbergGr__nby/2018-07-25.dzn";
% This model was based on the Flexible job shop example provided in Minizinc documentation


set of int: time = 0..maxDeparture; % timesteps in the studied duration
enum Car; % cars that need to be charged
enum Machine; % chargers in the station
array[Machine] of int: machineSpeed; % unitDemand/unitTime e.g. kWh/min
array[Machine] of int: machineLoad; % cost due to machine e.g. charging power in kW or grid cost
array[Car] of int: demandCar; % unitDemand e.g. kWh
array[Car] of int: arrivalCar; % arrival time of car
array[Car] of int: departureCar; % departure time of car



var int: peakCharging; %cost of resources
int: peakDumbCharging; %peak power for opportunistic charging
int: minArrival = min(arrivalCar); % earliest interesting time
int: maxDeparture = max(departureCar); % latest interesting time
array[Car] of var minArrival..maxDeparture: startCharge; % charging start time
array[Car] of var time: durationCharge; % charging duration 
array[Car] of var minArrival..maxDeparture: endCharge = [startCharge[c] + durationCharge[c] | c in Car]; % charging end time 
array[Car,Machine] of var opt time: optionalTaskStart; % optional task start for every machine
array[Car] of var int: respMachine = [sum([occurs(optionalTaskStart[c,m]) * m | m in Machine])| c in Car]; % which machine is charging which car


%Function to get the durationChargeof car charging if performed by a certain machine
function int: durOfCar(int: demand, int: speed) = ceil(demand / speed);



%Constraint one machine per car
constraint forall(c in Car)(
  alternative(startCharge[c], 
                   durationCharge[c], 
                   [optionalTaskStart[c,m]|m in Machine],
                   [durOfCar(demandCar[c],machineSpeed[m])|m in Machine])
);

%Constraint one car per machine
constraint forall(m in Machine)(
  disjunctive([optionalTaskStart[c,m]|c in Car],
                    [durOfCar(demandCar[c],machineSpeed[m])|c in Car])
  );

%Constraint number of resources to be k.
constraint cumulative(startCharge,
                                  durationCharge,
                                  [machineLoad[to_enum(Machine, respMachine[c])]|c in Car],
                                  peakCharging); 

%Cars are charged before they depart
constraint forall(c in Car)(departureCar[c] >= endCharge[c]);

%Cars are charged after they arrive
constraint forall(c in Car)(startCharge[c] >= arrivalCar[c]);



solve minimize(peakCharging);

output ["peakCharging = " ++ show(peakCharging) ++ "\n" ++
             "dumbChargingPeak = " ++ show(peakDumbCharging) ++ "\n" ++
            "Start time: " ++ show(startCharge) ++ "\n" ++
            "Charging duration: " ++ show(durationCharge) ++ "\n" ++
            "End time: " ++ show(endCharge) ++ "\n" ++
             "Order(car,Machine): " ++ "\n" ++ show2d(optionalTaskStart) ++ "\n" ++
             "latest Job ends:" ++ show(max(endCharge)) ++ "\n" ++
             "MachineForCar" ++ show([to_enum(Machine,respMachine[c])|c in Car])];