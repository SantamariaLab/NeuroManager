classdef WispConfig < MachineConfig
    properties
        OS_TENANT_NAME;
        OS_ComputeEndpoint;
        OS_IdentityEndpoint;
        OS_USERNAME;
        OS_PASSWORD;
        OS_KEY_NAME;
        network;
        powerStatePhrase;
        extAddressRoot;
        
        instanceName;
    end
    
    methods
        function obj = WispConfig(cloudInfoFile)
            obj = obj@MachineConfig(cloudInfoFile);
            
            % Wisp-specific details
            
        end
    end
end