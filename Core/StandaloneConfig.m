classdef StandaloneConfig  < MachineConfig
    methods
        function obj = StandaloneConfig(infoFile)
            obj = obj@MachineConfig(infoFile);
            
            % Standalone-specific details 
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

            obj.machineName = obj.resourceName;
            obj.id = obj.machineName;
            obj.commsID = obj.resourceName;
            
            if isfield(obj.infoData, 'flavor')
                obj.numProcessors       = obj.infoData.flavor.numProcessors;
                obj.coresPerProcessor   = obj.infoData.flavor.coresPerProcessor;
                obj.RAM                 = obj.infoData.flavor.RAM;
                obj.storage             = obj.infoData.flavor.storage;
            else
                error(['Infofile ' infoFile ' must specify flavor.']);
            end
        end
    end
    
end