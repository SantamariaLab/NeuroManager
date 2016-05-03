classdef StandaloneConfig  < MachineConfig
    methods
        function obj = StandaloneConfig(infoFile)
            obj = obj@MachineConfig(infoFile);
            
            % Standalone-specific details 
%             imageName = obj.resourceName;
            if isfield(obj.imageData, 'user')
                obj.userName = obj.imageData.user;
            else
                error(['Infofile ' infoFile ...
                       ' images section must specify user.']);
            end
            
            if isfield(obj.imageData, 'password')
                obj.password = obj.imageData.password;
            else
                error(['Infofile ' infoFile ...
                       ' images section must specify password.']);
            end

            if isfield(obj.imageData, 'ipAddress')
                obj.ipAddress = obj.imageData.ipAddress;
            else
                error(['Imagefile ' infoFile ...
                       ' images section must specify ipAddress.']);
            end
            
            obj.fsUserName = obj.userName;
            obj.jsUserName = obj.userName;
            obj.fsPassword = obj.password;
            obj.jsPassword = obj.password;
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