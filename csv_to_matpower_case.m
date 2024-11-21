function mpc = csv_to_matpower_case(bus_csv, branch_csv)
    % Läs in bus- och branch-data från CSV
    bus_data = readtable(bus_csv);
    branch_data = readtable(branch_csv);

    % Skapa Matpower-struktur
    mpc.version = '2';
    mpc.baseMVA = 100;  % Justera bas-MVA om det behövs

    % Omvandla BUS_I och branch F_BUS/T_BUS till numeriska värden
    [unique_buses, ~, bus_indices] = unique(bus_data.BUS_I); 
    numeric_bus_ids = 1:length(unique_buses);

    % Byt ut BUS_I med numeriska värden i bus_data
    bus_data.BUS_I = bus_indices;

    % Byt ut F_BUS och T_BUS med numeriska värden i branch_data
    branch_data.F_BUS = arrayfun(@(x) find(strcmp(unique_buses, x)), branch_data.F_BUS);
    branch_data.T_BUS = arrayfun(@(x) find(strcmp(unique_buses, x)), branch_data.T_BUS);

    % Bygg busmatrisen
    mpc.bus = [
        bus_data.BUS_I, bus_data.BUS_TYPE, bus_data.PD, bus_data.QD, ...
        bus_data.GS, bus_data.BS, bus_data.BUS_AREA, ...
        bus_data.VM, bus_data.VA, bus_data.BASE_KV, ...
        bus_data.ZONE, bus_data.VMAX, bus_data.VMIN
    ];

    % Bygg branchmatrisen
    mpc.branch = [
        branch_data.F_BUS, branch_data.T_BUS, branch_data.BR_R, branch_data.BR_X, ...
        branch_data.BR_B, branch_data.RATE_A, branch_data.RATE_B, branch_data.RATE_C, ...
        branch_data.TAP, branch_data.SHIFT, branch_data.BR_STATUS, ...
        branch_data.ANGMIN, branch_data.ANGMAX
    ];

    % Lägg till en generator vid slack-bussen (BUS_TYPE = 3)
    slack_bus_idx = find(mpc.bus(:, 2) == 3);  % Identifiera slack-bussen

    % Kontrollera om exakt en slack-bus finns
    if isempty(slack_bus_idx)
        error('Ingen slack-bus (BUS_TYPE = 3) hittades i bus-matrisen.');
    elseif numel(slack_bus_idx) > 1
        error('Flera slack-bussar hittades. Endast en slack-bus stöds.');
    end

    % Skapa gen-matrisen
    mpc.gen = [
        mpc.bus(slack_bus_idx, 1), 0, 0, 999, -999, mpc.bus(slack_bus_idx, 8), 100, 1, 999, -999
    ];
    % Kolumner: bus, Pg, Qg, Qmax, Qmin, Vg, mBase, status, Pmax, Pmin
end
