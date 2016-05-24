classdef CloudConfig  < MachineConfig
    properties
        instanceName;
        isWisp; % indicates need for removal of instance
        cloudInfoFile; % Used for Wisp removal
    end
    
    methods
        function obj = CloudConfig(infoFile)
                obj = obj@MachineConfig(infoFile);
            if (nargin==0 || isempty(infoFile))
                obj.instanceName = '';
                obj.userName = '';
                obj.password = '';
                obj.ipAddress = '';
            else
                % Cloud-specific details
                if isfield(obj.infoData, 'instanceName')
                    obj.instanceName    = obj.infoData.instanceName;
                else
                    error(['infoFile ' infoFile ' must specify instanceName.']);
                end

                if isfield(obj.imageData, 'user')
                    obj.userName = obj.imageData.user;
                else
                    error(['Infofile ' infoFile ...
                           ' images section must specify userName.']);
                end

                if isfield(obj.imageData, 'password')
                    obj.password = obj.imageData.password;
                else
                    error(['Infofile ' infoFile ...
                           ' images section must specify password.']);
                end

                % ==
                if isfield(obj.imageData, 'ipAddress')
                    obj.ipAddress = obj.imageData.ipAddress;
                else
                    error(['Imagefile ' infoFile ...
                           ' images section must specify ipAddress.']);
                end
                
                if isfield(obj.infoData, 'flavor')
                    obj.numProcessors = ...
                                     obj.infoData.flavor.numProcessors;
                    obj.coresPerProcessor = ...
                                     obj.infoData.flavor.coresPerProcessor;
                    obj.RAM        = obj.infoData.flavor.RAM;
                    obj.storage    = obj.infoData.flavor.storage;
                else
                    error(['Infofile ' infoFile ' must specify flavor.']);
                end
            end
            obj.isWisp = false; % default
            obj.cloudInfoFile = ''; % default
            obj.fsUserName = obj.userName;
            obj.jsUserName = obj.userName;
            obj.fsPassword = obj.password;
            obj.jsPassword = obj.password;
            obj.fsIpAddress = obj.ipAddress;
            obj.jsIpAddress = obj.ipAddress;

            obj.machineName = obj.instanceName;
            obj.id = obj.machineName;
            obj.commsID = obj.resourceName;
        end
    end
end
