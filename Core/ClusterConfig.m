classdef ClusterConfig  < MachineConfig
    properties
%         resourceType;
    end
    
    methods
        function obj = ClusterConfig(configFile)
            obj = obj@MachineConfig(configFile);
        end
    end
    
end