include "globals.mzn";
include "dataExamplewithLoadRES.dzn";
% This model was based on the Flexible job shop example provided in Minizinc documentation


set of int: dur = 0..maxDeparture; % timesteps in the studied duration
enum Car; % cars that need to be charged
enum Machine; % chargers in the station
array[Machine] of int: machineSpeed; % unitDemand/unitTime e.g. kWh/min
array[Machine] of int: machineLoad; % cost due to machine e.g. charging power in kW or grid cost
array[Car] of int: demandCar; % unitDemand e.g. kWh
array[Car] of int: arrivalCar; % arrival time of car
array[Car] of int: departureCar; % departure time of car


int: dayLength; %daylength input
set of int: timeDay = 1..dayLength; %time-steps in a day
array[timeDay] of int: load; % load
array[timeDay] of int: RES; %renewable energy sources production
array[timeDay] of var 0..max(Machine)*max(machineSpeed): chargingLoad ;%charging load in a day
array[timeDay] of var int:totalLoad = [chargingLoad[t]+load[t]-RES[t]| t in timeDay]; %totalLoad in a day



var int: peakCharging; %cost of resources
int: peakDumbCharging; %peak power for opportunistic charging
int: minArrival = min(arrivalCar); % earliest interesting time
int: maxDeparture = max(departureCar); % latest interesting time
array[Car] of var minArrival..maxDeparture: startCharge; % charging start time
array[Car] of var dur: durationCharge; % charging duration 
array[Car] of var minArrival..maxDeparture: endCharge = [startCharge[c] + durationCharge[c] | c in Car]; % charging end time 
array[Car,Machine] of var opt dur: optionalTaskStart; % optional task start for every machine
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

%Constraint number of resources to be peakCharging.
constraint cumulative(startCharge,
                                  durationCharge,
                                  [machineLoad[to_enum(Machine, respMachine[c])]|c in Car],
                                  peakCharging); 

%Cars are charged before they depart
constraint forall(c in Car)(departureCar[c] >= endCharge[c]);

%Cars are charged after they arrive
constraint forall(c in Car)(startCharge[c] >= arrivalCar[c]);

%estimate the charging load at each timestep
constraint forall(t in timeDay)(
     chargingLoad[t] = 0 + sum([machineLoad[to_enum(Machine, respMachine[c])]| c in Car where startCharge[c] <= t /\ endCharge[c] > t])
);

solve 
%:: seq_search([
%int_search(startCharge, smallest, indomain_min, complete),
%int_search(endCharge, impact, indomain_max, complete)
%int_search(respMachine, input_order, indomain_min, complete) 
%]) 
minimize (max(totalLoad)); % minimize k

output ["peakCharging = " ++ show(peakCharging) ++ "\n" ++
             "maxtotalLoad = " ++show(max(totalLoad)) ++ "\n" ++
             "dumbChargingPeak = " ++ show(peakDumbCharging) ++ "\n" ++
            "Start time: " ++ show(startCharge) ++ "\n" ++
            "Charging duration: " ++ show(durationCharge) ++ "\n" ++
            "End time: " ++ show(endCharge) ++ "\n" ++
             "Order(car,Machine): " ++ "\n" ++ show2d(optionalTaskStart) ++ "\n" ++
             "latest Job ends:" ++ show(max(endCharge)) ++ "\n" ++
             "MachineForCar" ++ show([to_enum(Machine,respMachine[c])|c in Car])];