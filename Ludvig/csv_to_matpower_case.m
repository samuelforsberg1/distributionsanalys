function [mpc, bus_data, branch_data] = csv_to_matpower_case(bus_csv, branch_csv, case_value)
    % Load bus and branch data from CSV
    [bus_data, branch_data, bus_data_cpy, branch_data_cpy] = load_csv_data(bus_csv, branch_csv);

    % Filter buses and branches based on case_value
    [bus_data, branch_data] = filter_buses_and_branches(bus_data, branch_data, bus_data_cpy, case_value);

    % Create Matpower structure
    mpc = create_matpower_structure(bus_data, branch_data, branch_data_cpy);

    % Load load profiles for each bus
    mpc.load_profiles = load_load_profiles(bus_data);
end