%% Function Name: create_matpower_structure
% Description: Read the load data and add it to the specific bus which it
% is related to. Note that the load data will be mapped to the unique mpc 
% index of the bus it is related to.
%
% Inputs:
%     bus data - bus_ data
%
% Outputs:
%     load_profiles - load profile for each bus and relate to the unique
%     mpc idx of the bus it is related to.
%
% $Revision: R2023b$ 
% $Author: Ludvig Syrén, ludvig.syren@angstrom.uu.se$
% $Date: November 27, 2024$
%---------------------------------------------------------
function load_profiles = load_load_profiles(bus_data)
    load_profiles = containers.Map('KeyType','double', 'ValueType','any');
    [unique_buses, ~, bus_indices] = unique(bus_data.BUS_I);
    for i = 1:height(bus_data)
        bus_name = strrep(unique_buses(i),'.','');
        bus_val=bus_indices(i);
        load_profile_file = strcat(bus_name, '.txt');
        load_profile_file = strcat("Load\",load_profile_file);
        if isfile(load_profile_file)
            load_profile = importdata(load_profile_file);
            load_profiles(bus_val) = load_profile;
        else
            continue;
        end
    end
end