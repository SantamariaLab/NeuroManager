% CloudManagementType
% Associates json data with NM Cloud Management classes
classdef CloudManagementType
    properties
        constrFunc;
    end
    methods
        function t = CloudManagementType(constrFunc)
            t.constrFunc = constrFunc; % Machine constructor
        end
    end
    enumeration
        UNASSIGNED              (0)
        UNKNOWN                 (0)
        
        ChameleonOS_KVM         (@CCCloudManagement)
        Rackspace               (@RSCloudManagement)
    end
end 