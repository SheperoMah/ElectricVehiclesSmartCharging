function combinedStruct = combineNonResidentialTrips(struct)
    
   combinedStruct.arrival = [struct.WorkHomeArrival; ...
       struct.OtherHomeArrival];
   combinedStruct.arrival = combinedStruct.arrival(...
       isfinite(combinedStruct.arrival));
   
   
   combinedStruct.departure = [struct.WorkHomeDeparture; ...
       struct.OtherHomeDeparture];
   combinedStruct.departure = combinedStruct.departure(...
       isfinite(combinedStruct.departure));
   
    combinedStruct.distance = [struct.WorkHomeDistance; ...
       struct.OtherHomeDistance];
   combinedStruct.distance = combinedStruct.distance(...
       isfinite(combinedStruct.distance));
   

end