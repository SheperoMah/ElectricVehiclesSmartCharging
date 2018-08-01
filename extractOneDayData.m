% author := Mahmoud Sheperi <mahmoud.shepero@angstrom.uu.se>
% date := 26 July 2018
% name := extract station data into text files

function [arriveTime, departTime, consump] = ...
         extractOneDayData(date, ...
                           parkTime, ... 
                           energyCons, ...
                           deptTime, ...
                           resolution) % resolution in minutes

idx = parkTime > date & parkTime < date+days(1);

% assume any car arrives 0-resolution is arriving at the begining of the event
arriveTime = floor((minute(parkTime(idx)) + 60*hour(parkTime(idx))) ...
    /resolution); 

departTime = ceil((minute(deptTime(idx)) + 60*hour(deptTime(idx))) ...
    /resolution); % resolution

consump = ceil(energyCons(idx)*1000 * 60/ resolution); % W(resolution)


end