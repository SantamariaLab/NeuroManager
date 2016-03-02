classdef CloudConfig  < MachineConfig
    properties
%         deleteWhenDoneFlag; % Not used for now
        OS_TENANT_NAME;
        OS_ComputeEndpoint;
        OS_IdentityEndpoint;
        OS_USERNAME;
        OS_PASSWORD;
        OS_KEY_NAME;
        network;
        powerStatePhrase;
        extAddressRoot;
        
        imageRef;
        flavorRef;
        cloudWorkDir;
        hostKeyFingerprint;
        instanceUsername;
        
        instance;

%         quotas; % Not used for now
    end
    
    methods
        function obj = CloudConfig(configFile)
            obj = obj@MachineConfig(configFile);
            % We already know from previous line that configFile and
            % imageFile exist and are parseable.  We just need to get the
            % Cloud specific stuff out of them.
            configData = loadjson(configFile);
            imageFile = configData.image.file;
            imageData = loadjson(imageFile); 
            cloudInfoFile = configData.infoFile;
            if ~exist(cloudInfoFile, 'file') == 2
                error(['Error: NeuroManager could not find the file '...
                       cloudInfoFile ' during configuration processing.']);
            end
            try
                cloudInfoData = loadjson(cloudInfoFile);
            catch ME
                msg = ['Error processing %s. Possible syntax error.\n' ...
                       'Information given is: %s, %s.'];
                error(msg, cloudInfoFile, ME.identifier, ME.message);
            end
            
            obj.OS_TENANT_NAME      = cloudInfoData.OS_TENANT_NAME;
            obj.OS_ComputeEndpoint  = cloudInfoData.OS_ComputeEndpoint;
            obj.OS_IdentityEndpoint = cloudInfoData.OS_IdentityEndpoint;
            obj.OS_USERNAME         = cloudInfoData.OS_USERNAME;
            obj.OS_PASSWORD         = cloudInfoData.OS_PASSWORD;
            obj.OS_KEY_NAME         = cloudInfoData.OS_KEY_NAME;
            obj.network             = cloudInfoData.network;
            obj.powerStatePhrase    = cloudInfoData.powerStatePhrase;
            obj.extAddressRoot      = cloudInfoData.extAddressRoot;

            obj.imageRef            = imageData.imageRef;
            obj.flavorRef           = imageData.flavorRef; 
            obj.cloudWorkDir        = imageData.workDir; 
            obj.hostKeyFingerprint  = imageData.hostKeyFingerprint;
            obj.instanceUsername    = imageData.userName;
        end
    end
end
