% author := Mahmoud Sheperi <mahmoud.shepero@angstrom.uu.se>
% date := 26 July 2018
% name := extract station data into text files


parkingLotNames = categorical(Plats);
uniqueNames = categories(parkingLotNames);
stationNames = categorical(Laddstation);
station = uniqueNames(1);
stationString = matlab.lang.makeValidName(char(station));
if(~exist(stationString, 'dir'))
    mkdir(stationString)
end
index = strcmp(Plats, station); %index of station
theoPower = Energi(index)./Tidsperiod(index)*3600;
chargePower = 3700;%quantile(theoPower,0.999);
numChargers = 16;
powerChargers = ones(16,1) * chargePower;

disConTime = datetime(Slutladdsession);
conTime = datetime(Startladdsession);


maxDate = max(conTime(index)); %can be set manually
minDate = min(conTime(index));% can be set manually

monNu = month(maxDate);
yr = year(maxDate);
dayNu = day(maxDate);
today = datetime(yr, monNu, dayNu);
i = today;
tomorrow = today + days(1);

while i < tomorrow && i > minDate-days(1)
     
    [arrive, depart, energy] = extractOneDayData(i, ...
        conTime(index), Energi(index), disConTime(index), 15);
    peakDumbCharging = estimatePeakLoad(arrive, depart, energy, chargePower);
    
    numCars = length(arrive);
    txt = ['peakDumbCharging = ' num2str(peakDumbCharging) '; \n'...
           'Machine = anon_enum(' num2str(numChargers) '); \n', ...
           'machineSpeed = ' strrep(mat2str(powerChargers),';',',') '; \n', ... %charging power in W
           'machineLoad = ' strrep(mat2str(powerChargers),';',',') '; \n', ... %charing power in W
           'Car = anon_enum(' num2str(numCars) '); \n', ...
           'demandCar = ' strrep(mat2str(energy),';',',') '; \n', ...  % energy in W(resolution)
           'arrivalCar = ' strrep(mat2str(arrive),';',',') '; \n', ...
           'departureCar = ' strrep(mat2str(depart),';',',') '; \n'];
    
    
    filename = [stationString '/' datestr(i, 'yyyy-mm-dd') '.dzn'];
    file = fopen(filename, 'w+');
    fprintf(file, txt);
    fclose(file);
    tomorrow = i;
    i = i - days(1);
end
