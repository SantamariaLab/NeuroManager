classdef MLCompileConfig  < MachineConfig
    methods
        function obj = MLCompileConfig(infoFile)
            obj = obj@MachineConfig(infoFile);
            
            % MLCompile-specific details 
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
                error(['Infofile ' infoFile ...
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
            
            if (isempty(obj.compilerDir) || ...
                isempty(obj.compiler) || isempty(obj.xCompDir))
                error(['Infofile ' infoFile ...
                       ' matlab section must specify compilerDir,'...
                       ' compiler, and xCompDir.']);
            end
        end
        
        function config = getMachine(obj)
            config = obj;
        end
    end
end
