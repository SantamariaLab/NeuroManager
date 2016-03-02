classdef StandaloneConfig  < MachineConfig
    properties
%         resourceType;
    end
    
    methods
        function obj = StandaloneConfig(configFile)
            obj = obj@MachineConfig(configFile);
%             obj.resourceType = 'STANDALONE';

        end
    end
    
end