%% Function Name: create_matpower_structure
% Description: Read the bus and branch data and transform to the matpower
% case format which is necessary to perfrom powerflow with matpower.
%
% Inputs:
%     bus data - bus_ data
%     branch_data - branch data
%     bus_data_cpy - copy of bus data
%
% Outputs:
%     mpc - bus and branch data in the matpower case format
%
% $Revision: R2023b$ 
% $Author: Ludvig Syrén, ludvig.syren@angstrom.uu.se$
% $Date: November 27, 2024$
%---------------------------------------------------------

function mpc = create_matpower_structure(bus_data, branch_data, branch_data_cpy)
    mpc.version = '2';
    mpc.baseMVA = 100;  % Adjust base MVA if needed

    % Convert BUS_I and branch F_BUS/T_BUS to numeric values
    %unique_buses - contains the unique buses in the data, removed
    %dupliactes
    %bus_indices - the unique indexation for each unique bus
    [unique_buses, ~, bus_indices] = unique(bus_data.BUS_I); 
    numeric_bus_ids = 1:length(unique_buses);

    % Replace BUS_I with numeric values in bus_data
    bus_data.BUS_I = bus_indices;

    % Replace F_BUS and T_BUS with numeric values in branch_data
    branch_data.F_BUS = arrayfun(@(x) find(strcmp(unique_buses, x)), branch_data.F_BUS);
    branch_data.T_BUS = arrayfun(@(x) find(strcmp(unique_buses, x)), branch_data.T_BUS);

    % Extract voltage levels from branch data
    extract_voltage_level = @(x) str2double(regexp(x, '(?<=R\d)(47|11|0\.415|0\.23)(?=T)', 'match', 'once'));
    F_BUS_voltage = arrayfun(extract_voltage_level, branch_data_cpy.F_BUS);
    T_BUS_voltage = arrayfun(extract_voltage_level, branch_data_cpy.T_BUS);

    % Determine voltage level relationship
    voltage_level_relation = determine_voltage_level_relation(F_BUS_voltage, T_BUS_voltage, height(branch_data));

    % Build bus matrix
    mpc.bus = [
        bus_data.BUS_I, bus_data.BUS_TYPE, bus_data.PD, bus_data.QD, ...
        bus_data.GS, bus_data.BS, bus_data.BUS_AREA, ...
        bus_data.VM, bus_data.VA, bus_data.BASE_KV, ...
        bus_data.ZONE, bus_data.VMAX, bus_data.VMIN
    ];

    % Build branch matrix
    mpc.branch = [
        branch_data.F_BUS, branch_data.T_BUS, branch_data.BR_R, branch_data.BR_X, ...
        branch_data.BR_B, branch_data.RATE_A, branch_data.RATE_B, branch_data.RATE_C, ...
        branch_data.TAP, branch_data.SHIFT, branch_data.BR_STATUS, ...
        branch_data.ANGMIN, branch_data.ANGMAX, voltage_level_relation
    ];

    % Add a generator at the slack bus (BUS_TYPE = 3)
    slack_bus_idx = find(mpc.bus(:, 2) == 3);  % Identify the slack bus

    % Check if exactly one slack bus exists
    if isempty(slack_bus_idx)
        error('No slack bus (BUS_TYPE = 3) found in the bus matrix.');
    elseif numel(slack_bus_idx) > 1
        error('Multiple slack buses found. Only one slack bus is supported.');
    end

    % Create gen matrix
    mpc.gen = [
        mpc.bus(slack_bus_idx, 1), 0, 0, 999, -999, mpc.bus(slack_bus_idx, 8), 100, 1, 999, -999
    ];
    % Columns: bus, Pg, Qg, Qmax, Qmin, Vg, mBase, status, Pmax, Pmin
end

function voltage_level_relation = determine_voltage_level_relation(F_BUS_voltage, T_BUS_voltage, num_branches)
    voltage_level_relation = zeros(num_branches, 1);
    for i = 1:num_branches
        if F_BUS_voltage(i) == T_BUS_voltage(i)
            switch F_BUS_voltage(i)
                case 47
                    voltage_level_relation(i) = 1;
                case 11
                    voltage_level_relation(i) = 2;
                case 0.415
                    voltage_level_relation(i) = 3;
                case 0.23
                    voltage_level_relation(i) = 4;
            end
        else
            voltage_level_relation(i) = 0;
        end
    end
end