% The MachineConfig class and subclasses gather data from various files
% and user parameters to supply NeuroManager with a unified group of data
% for machine setup and compatibility checking.

classdef MachineConfig < matlab.mixin.Heterogeneous
    properties 
        machineName;
        resourceName;
        resourceType;
        userName;
        ipAddress;
        numSimulators;
        workDir;
        simCoreName;
        simCoreVersion; % May not belong here
        
        % flavor
        numCores;
        RAM;
        storage;
        
        % matlab
        compilerDir;
        compiler;
        executable;
        mcrDir;
        xCompDir;
    end
    
    methods
        function obj = MachineConfig(configFile)
            if nargin==0
                obj.machineName = '';
                obj.resourceName = '';
                obj.resourceType = '';
                obj.userName = '';
                obj.ipAddress = '';
                obj.numSimulators = -1;
%                 obj.workDir = '';
                obj.simCoreName = '';
                obj.numCores = 0;
                obj.RAM = 0;
                obj.storage = 0;
                obj.compilerDir = '';
                obj.compiler = '';
                obj.executable = '';
                obj.mcrDir = '';
                obj.xCompDir = '';
            else
                % Pull in the configFile (JSON format) and fill in the data
                % related to this class
                if ~exist(configFile, 'file') == 2
                    error(['Error: NeuroManager could not find the file '...
                           configFile ' during configuration processing.']);
                end
                try
                    configData = loadjson(configFile);
                catch ME
                    msg = ['Error processing %s. Possible syntax error.\n' ...
                           'Information given is: %s, %s.'];
                    error(msg, configFile, ME.identifier, ME.message);
                end
%                 obj.setMachineName(configData.machineName);
                obj.machineName = configData.machineName;
                obj.resourceName = configData.resourceName;
                obj.resourceType = configData.resourceType;
                obj.userName = configData.userName;
%                 obj.ipAddress = configData.ipAddress;
                imageFile = configData.image.file;
                if ~exist(imageFile, 'file') == 2
                    error(['Error: NeuroManager could not find the file '...
                           imageFile ' during configuration processing.']);
                end
                try
                    imageData = loadjson(imageFile); 
                catch ME
                    msg = ['Error processing %s. Possible syntax error.\n' ...
                           'Information given is: %s, %s.'];
                    error(msg, imageFile, ME.identifier, ME.message);
                end
                obj.ipAddress = imageData.ipAddress;
                obj.compilerDir = imageData.matlab.compilerDir;
                obj.compiler = imageData.matlab.compiler;
                obj.executable = imageData.matlab.executable;
                obj.mcrDir = imageData.matlab.mcrDir;
                obj.xCompDir = imageData.matlab.xCompDir;
                obj.simCoreName = imageData.simCores{1,1}.name; % Temporary
            end
        end
    end
    
    % None of these works for some unknown reason - no error; they just
    % don't set.  The gets seem to work fine...
    methods (Sealed)
        % ---
%         function setResourceName(obj, name)
%             obj.resourceName = name;
%         end
        
        function name = getResourceName(obj)
            name = obj.resourceName;
        end
        
        % ---
%         function setResourceType(obj, type)
%             obj.resourceType = type;
%         end
        
        function type = getResourceType(obj)
            type = obj.resourceType;
        end
        
        % ---
%         function setMachineName(obj, name)
%             obj.machineName = name;
%         end
        
        function name = getMachineName(obj)
            name = obj.machineName;
        end
        
        % ---
%         function setUserName(obj, name)
%             obj.userName = name;
%         end
        
        function name = getUserName(obj)
            name = obj.userName;
        end
        
        % ---
%         function setIpAddress(obj, ipAddress)
%             obj.ipAddress = ipAddress;
%         end
        
        function ipAddress = getIpAddress(obj)
            ipAddress = obj.ipAddress;
        end
        
        % ---
%         function setNumSimulators(obj, num)
%             obj.numSimulators = num;
%         end
        
        function num = getNumSimulators(obj)
            num = obj.numSimulators;
        end
        
        % ---
%         function setWorkDir(obj, dir)
%             obj.workDir = dir;
%         end
        
        function dir = getWorkDir(obj)
            dir = obj.workDir;
        end

        % ---
%         function setSimCoreName(obj, name)
%             obj.simCoreName = name;
%         end
        
        function name = getSimCoreName(obj)
            name = obj.simCoreName;
        end
        
        % ---
%         function setNumCores(obj, num)
%             obj.numCores = num;
%         end
        
        function num = getNumCores(obj)
            num = obj.numCores;
        end
        
        % ---
%         function setRAM(obj, ram)
%             obj.RAM = ram;
%         end
        
        function ram = getRAM(obj)
            ram = obj.RAM;
        end
        
        % ---
%         function setStorage(obj, storage)
%             obj.Storage = storage;
%         end
        
        function storage = getStorage(obj)
            storage = obj.storage;
        end
        
        % ---
        function dir = getCompilerDir(obj)
            dir = obj.compilerDir;
        end
        
        % ---
        function dir = getCompiler(obj)
            dir = obj.compiler;
        end
        
        % ---
        function executable = getExecutable(obj)
            executable = obj.executable;
        end
        
        % ---
        function dir = getMcrDir(obj)
            dir = obj.mcrDir;
        end
        
        % ---
        function dir = getXCompDir(obj)
            dir = obj.xCompDir;
        end
    end
end
