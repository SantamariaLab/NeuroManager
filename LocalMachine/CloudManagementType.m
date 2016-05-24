% CloudManagementType
% Associates cloud type as specified in the json data with NM Cloud
% Management class constructors 
classdef CloudManagementType
    properties
        constrFunc;
    end
    methods
        function t = CloudManagementType(constrFunc)
            t.constrFunc = constrFunc; 
        end
    end
    enumeration
        UNASSIGNED              (0)
        UNKNOWN                 (0)
        
        ChameleonOS_KVM         (@CCCloudManagement)
        Rackspace               (@RSCloudManagement)
    end
end 