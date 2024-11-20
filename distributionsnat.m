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

%--------------------------------------------------------------------------
%% 2. Load the power system case and identify slack bus indices

mpcRefCase = NORSKANÄTMODELLENLÄGGSHÄR; % Unchanged reference case file
mpc = mpcRefCase;   % mpc file to be modified

busIdxSlack = find(mpc.bus(:,2)==3);              % Slack bus index in mpc.bus
genIdxSlack = (find(mpc.gen(:,1)==busIdxSlack));  % Slack bus index in mpc.gen
genIdxSlack = genIdxSlack(1);                     % If there are more than one generator

%--------------------------------------------------------------------------
%% 4. Read input load data (power consumption and production)
%obs. här är det användbart om man både läser in en tidsvektor och
%effektbehovs/produktionsvektor. Antingen läser man in detta från en och
%samma fil till alla EVs och PVs eller så läser man in från en fil i taget
%till respektive EV och PV.

% EV data
variableA = load('filename.mat');

% PV data
variableB = load('filename.mat');
    

% Define parameters
t       = 1:length(variableA.timeVector);    % Time vector [resolution]  
L       = length(t);        % Length of time vector

%--------------------------------------------------------------------------
%% 6. Solve the power flow at each time step

loadBusVoltage = zeros(L,sum(mpc.bus(:,2)==1)); %Pre allocation
pvBusVoltage = zeros(L,sum(mpc.bus(:,2)==2));

mpc.gen(genIdxSlack,4)    = qMaxSlack;         % Maximum reactive power supply at slack bus (unlimited)
mpc.gen(genIdxSlack,5)    = qMinSlack;         % Minimum reactive power supply at slack bus (unlimited)

mpopt = mpoption('out.all',0,'verbose',0,'pf.alg',solver,'pf.enforce_q_lims',qLim);  % Stop printout, full Newton Raphson method, respect Q-limits or not
mpcFlatStart = runpf(mpc,mpopt);            % Flat start case data

for indT = 1:L                              % Loop through all time steps
    disp(indT)

    if flatStart == 1
        mpc = mpcFlatStart;  % Apply flat start in every time step
    end
    
    mpc.gen(idxPV,2) = PVdata(indT,:);        % Set PV power generation at time step t
    mpc.bus(idxEV,3:4) = EVdata(indT,:);        % Set EV power consumption at time step t

    ind0 = find(mpc.gen(:,2)==0);           % Deactivate generators with P==0
    mpc.gen(ind0,8) = 0;                    % Gen status = 0
    mpc.gen(genIdxSlack,8) = 1;             % Re-activate slack bus generator

    % ---------------------------------------------------------------------
    % Solve the power flow case at time step t
    results = runpf(mpc,mpopt);



    %% 6.6 Save data for converged and non converged solutions
    if results.success == 1    % If we have found a converged solution
        pvBusVoltage(indT,:) = results.bus(mpc.gen(idxPV,1),8)';     % PV bus voltage (PV parks) in pu at time step t
        loadBusVoltage(indT,:) = results.bus(mpc.bus(:,2)==1,8)';        % PQ bus voltage (load buses) in pu at time step t
        
        mpc = results;  % Aviod flat start in next time step
        mpc.gen(:,8) = 1;                       % Set all generators' status = 1 (active)
    else
        pvBusVoltage(indT,:) = NaN;     % Bus voltage (PV parks) in pu at time step t (non converged solution)
        loadBusVoltage(indT,:) = NaN;     % Bus voltage (load buses) in pu at time step t (non converged solution)

        mpc = mpcFlatStart;  % Apply a flat start in next time step
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
plot(G2.timeVector,loadBusVoltage);
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