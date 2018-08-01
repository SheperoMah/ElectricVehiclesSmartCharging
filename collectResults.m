% Assemble results and plot them
% Author := Mahmoud Shepero
% email := mahmoud.shepero@angstrom.uu.se


%%

folderName = 'AtriumLjunbergGr__nby';
chargingPower = 3700;

%% READ THE RESULTS


delimiter = ' ';
startRow = 2;
formatSpec = '%s%f%f%f%[^\n\r]';

fileID = fopen([folderName,'/completedResultsCleaned.txt'], 'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
fclose(fileID);

caseName = dataArray{:, 1};
optimizedPeak = dataArray{:, 2};
dumbPeak = dataArray{:, 3};
computationTime = dataArray{:, 4};

clearvars folderName delimiter startRow formatSpec fileID dataArray ans;

%%

numChargersDumb = dumbPeak/chargingPower;
numChargersOpt = optimizedPeak/chargingPower;
numChargersRed = numChargersDumb-numChargersOpt;

%% PLOT SOME ANALYSIS

figure
scatter(numChargersDumb, numChargersOpt, 'HandleVisibility','off', ...
    'LineWidth', 1, 'sizeData', 50)
hold on
plot(0:max(numChargersDumb), 0:max(numChargersDumb),'r', 'linewidth', 1)
xlabel('Number of chargers (dumb charging)')
ylabel('Number of chargers (smart charging)')
set(gca, 'fontsize', 18)
legend('dumb = smart')
pause(5) % wait few seconds, then close figure
close()

%%

figure
scatter(numChargersDumb, numChargersRed, 'HandleVisibility','off', ...
    'LineWidth', 1, 'sizeData', 50)
xlabel('Number of chargers (dumb charging)')
ylabel('Number of delayed chargers')
set(gca, 'fontsize', 18)
pause(5)% wait few seconds, then close figure
close()

%%

figure
scatter(numChargersRed, computationTime, 'HandleVisibility','off', ...
    'LineWidth', 1, 'sizeData', 50)
ylabel('Computation time (Seconds)')
xlabel('Number of delayed chargers')
set(gca, 'fontsize', 18)
pause(5)% wait few seconds, then close figure
close()

%%

figure
histogram(categorical(numChargersRed))
xlabel('Number of delayed chargers')
ylabel('Number of days')
set(gca, 'fontsize', 18)
pause(5)% wait few seconds, then close figure
close()


%%















