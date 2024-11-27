%% Function Name: filter_buses_and_branches
% Description: Filter the bus and branch data depending on the different
% use cases. Outputs bus and branch data with only buses and branches
% related to the specific case.
%
% ToDo (Ludvig Syrén): Cases are hardcoded for the different Norwegian grid use case, make
% it more general by adding a string as argument to function.
%
% Inputs:
%     bus data
%     branch data
%     bus_data_cpy - 
%     case_value - value for the different cases
%
% Outputs:
%     bus_data - Data which contains the buses related to the specific case
%     branch_data - Data which contains the buses related to the specific case
% $Revision: R2023b$ 
% $Author: Ludvig Syrén, ludvig.syren@angstrom.uu.se$
% $Date: November 27, 2024$
%---------------------------------------------------------

function [bus_data, branch_data] = filter_buses_and_branches(bus_data, branch_data, bus_data_cpy, case_value)
    switch case_value
        case 'r1'
            bus_filter = startsWith(bus_data.BUS_I, 'r1');
        case 'r2'
            bus_filter = startsWith(bus_data.BUS_I, 'r2');
        case 'r1r2s1'
            bus_filter = ~strcmp(bus_data.BUS_I, 'r2v47.0b1');
        case 'r1r2s2'
            bus_filter = ~strcmp(bus_data.BUS_I, 'r1v47.0b1');
        otherwise
            error('Invalid case_value');
    end

    bus_data = bus_data(bus_filter, :);
    branch_filter = ismember(branch_data.F_BUS, bus_data_cpy.BUS_I(bus_filter)) & ...
                    ismember(branch_data.T_BUS, bus_data_cpy.BUS_I(bus_filter));
    branch_data = branch_data(branch_filter, :);
end