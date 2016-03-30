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
        
        instanceName;
%         imageRef;
%         flavorRef;
%         cloudWorkDir;
%         hostKeyFingerprint;
%         instanceUsername;
%         keyFile;
%         curlDir;
        
%         instance;

%         quotas; % Not used for now
    end
    
    methods
        function obj = CloudConfig(infoFile)
            obj = obj@MachineConfig(infoFile);
            
            % Cloud-specific details
            if isfield(obj.infoData, 'userName')
                obj.userName = obj.infoData.userName;
            else
                error(['Infofile ' infoFile ' must specify userName.']);
            end
            obj.fsUserName = obj.userName;
            obj.jsUserName = obj.userName;
            
            if isfield(obj.infoData, 'password')
                obj.password = obj.infoData.password;
            else
                error(['Infofile ' infoFile ' must specify password.']);
            end
            obj.fsPassword = obj.password;
            obj.jsPassword = obj.password;

            if isfield(obj.imageData, 'ipAddress')
                obj.ipAddress = obj.imageData.ipAddress;
            else
                error(['Imagefile ' imageFile ' must specify ipAddress.']);
            end
            obj.fsIpAddress = obj.ipAddress;
            obj.jsIpAddress = obj.ipAddress;
            
            if isfield(obj.infoData, 'instanceName')
                obj.instanceName    = obj.infoData.instanceName;
            else
                error(['infoFile ' infoFile ' must specify instanceName.']);
            end

            obj.machineName = obj.instanceName;
            obj.userName = obj.infoData.userName;
            obj.id = obj.machineName;
            obj.commsID = obj.resourceName;
            
            % Possibly superfluous for this type
            cloudInfoFile = obj.infoData.cloudInfoFile;
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

        end
        

    end
end
