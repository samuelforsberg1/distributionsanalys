function [] = distributionsnat()
%% Info
% Distributionsnätskursen

close all;
tic;

%--------------------------------------------------------------------------
%% 1. Define contants, solver and other parameters
solver = 'NR';          % Solver used in runpf {'NR','FDXB','FDBX','GS'}
qLim = 1;               % Enforce generator Q limits? (0=no, 1=yes)
flatStart = 0;          % Apply flat start in every time step (0=no, 1=yes)
idxPV = 1;
%--------------------------------------------------------------------------
%% 2. Load the power system case and identify slack bus indices
%{
Cases:
r1 - Left side of grid
r2 - Right side of grid
r1r2s1 - Complete grid fed from left
r1r2s2 - Complete grid fed from right
%}
[mpc, bus_data, branch_data] = csv_to_matpower_case("bus.csv", "branch.csv","r1");
[unique_buses, ~, bus_indices] = unique(bus_data.BUS_I);
% Adding loads
correlation_table = table(bus_indices, unique_buses);

%Lägg alla bussar i samma loss zone
mpc.bus(:,8)=1;
%Lägg till Impedans för samtliga ledningar



busIdxSlack = find(mpc.bus(:,2)==3);              % Slack bus index in grid.bus
busIdxSlack
genIdxSlack = (find(mpc.gen(:,1)==busIdxSlack));  % Slack bus index in grid.gen
busIdxSlack
%genIdxSlack = genIdxSlack(1);                     % If there are more than one generator

%--------------------------------------------------------------------------
%% 4. Read input load data (power consumption and production)
%obs. här är det användbart om man både läser in en tidsvektor och
%effektbehovs/produktionsvektor. Antingen läser man in detta från en och
%samma fil till alla EVs och PVs eller så läser man in från en fil i taget
%till respektive EV och PV.

% EV data
%variableA = load('filename.mat');

% PV data
PV_data_raw = readtable("Generation\FINE-PVgen-main\FINE-PVgen-main\PVgenerator\PV generation.xlsx");
%This data is recorded hourly for six years. 1/1/2015 --> 31/12/2020. 

L = length(PV_data_raw.Rakkestad);
L=24;

%Here timeVector ranges from 1:length(PV_data)
timeVector = 1:L;
%--------------------------------------------------------------------------
%% 6. Solve the power flow at each time step

loadBusVoltage = zeros(L,sum(grid.bus(:,2)==1)); %Pre allocation
pvBusVoltage = zeros(L,sum(grid.bus(:,2)==2));

%grid.gen(genIdxSlack,4)    = qMaxSlack;         % Maximum reactive power supply at slack bus (unlimited)
%grid.gen(genIdxSlack,5)    = qMinSlack;         % Minimum reactive power supply at slack bus (unlimited)

mpopt = mpoption('out.all',0,'verbose',0,'pf.alg',solver,'pf.enforce_q_lims',qLim);  % Stop printout, full Newton Raphson method, respect Q-limits or not
gridFlatStart = runpf(grid,mpopt);            % Flat start case data

for indT = 1:L                            % Loop through all time steps
    t = indT;
    disp(t)

    if flatStart == 1
        grid = gridFlatStart;  % Apply flat start in every time step
    end
    
    grid.gen(idxPV,2) = PV_data_raw.Rakkestad(indT);          % Set PV power generation at time step t
    %grid.bus(idxEV,3:4) = EVdata(indT,:);        % Set EV power consumption at time step t

    ind0 = find(grid.gen(:,2)==0);           % Deactivate generators with P==0
    grid.gen(ind0,8) = 0;                    % Gen status = 0
    grid.gen(genIdxSlack,8) = 1;             % Re-activate slack bus generator

    % ---------------------------------------------------------------------
    % Solve the power flow case at time step t
    results = runpf(grid,mpopt);



    %% 6.6 Save data for converged and non converged solutions
    if results.success == 1    % If we have found a converged solution
        pvBusVoltage(indT,:) = results.bus(grid.gen(idxPV,1),8)';     % PV bus voltage (PV parks) in pu at time step t
        loadBusVoltage(indT,:) = results.bus(grid.bus(:,2)==1,8)';        % PQ bus voltage (load buses) in pu at time step t
        
        grid = results;  % Aviod flat start in next time step
        grid.gen(:,8) = 1;                       % Set all generators' status = 1 (active)
    else
        pvBusVoltage(indT,:) = NaN;     % Bus voltage (PV parks) in pu at time step t (non converged solution)
        loadBusVoltage(indT,:) = NaN;     % Bus voltage (load buses) in pu at time step t (non converged solution)

        grid = gridFlatStart;  % Apply a flat start in next time step
        disp("Cannot find a converged solution for time step "+num2str(t)+". Applying flat start.")
    end

end

%--------------------------------------------------------------------------
%% 7. Calculate results
% Code to calculate and process results

%--------------------------------------------------------------------------
%% 8. Plots and final printout

% tex. bus spänning som funktion av tid etc...
figLoadBusVoltage = figure;
hold on
plot(timeVector,loadBusVoltage);
xlabel('Time');
ylabel('Bus voltage magnitude (load buses) [pu]');
hold off
saveas(figLoadBusVoltage,'figLoadBusVoltage.jpg','jpeg');



simTime = toc;
disp(['Simulation took ',num2str(simTime),' seconds to complete.'])

% Save data in .mat file
fileName = ['results',caseFile,num2str(year),'WP',num2str(windPen),'UCUT',num2str(Ucutin),'SUT',num2str(startUpTime)];
save(fileName);
end