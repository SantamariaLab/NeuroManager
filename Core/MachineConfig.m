% The MachineConfig class and subclasses gather data from various files
% and user parameters to supply NeuroManager with a unified group of data
% for machine setup and compatibility checking.

classdef MachineConfig < matlab.mixin.Heterogeneous  & dynamicprops
    properties 
        machineName;
        resourceName;
        resourceType;
        userName;
        password;
        simCores;
        ipAddress;
        hostKeyFingerprint;
        numSimulators;
        workDir;
        
        % flavor
        numProcessors;
        coresPerProcessor;
        RAM;
        storage;
        
        % matlab
        compilerDir;
        compiler;
        executable;
        mcrDir;
        xCompDir;
        
        % will be set later
        requestedSimCoreName;
        assignedSimCoreName;
        commsID;
        instanceName;
%         uploadMachineConfig; % for uploading paths etc
    end
    
    methods
        function obj = MachineConfig(infoFile)
            if nargin==0
                obj.machineName = '';
                obj.resourceName = '';
                obj.resourceType = '';
                obj.userName = '';
                obj.password = '';
                obj.ipAddress = '';
                obj.hostKeyFingerprint = '';
                obj.requestedSimCoreName = '';
                obj.assignedSimCoreName = '';
                obj.numSimulators = -1;
                obj.workDir = '';
                obj.simCores = {};
                
                obj.numProcessors = 1;
                obj.coresPerProcessor = 1;
                obj.RAM = 0;
                obj.storage = 0;
                
                obj.compilerDir = '';
                obj.compiler = '';
                obj.executable = '';
                obj.mcrDir = '';
                obj.xCompDir = '';
                obj.commsID = '';
                obj.instanceName = '';
%                 obj.uploadMachineConfig = struct;
            else
                % Pull in the infoFile (JSON format) and fill in the data
                % related to this class
                if ~exist(infoFile, 'file') == 2
                    error(['Error: NeuroManager could not find the file '...
                           infoFile ' during configuration processing.']);
                end
                try
                    infoData = loadjson(infoFile);
                catch ME
                    msg = ['Error processing %s. Possible syntax error.\n' ...
                           'Information given is: %s, %s.'];
                    error(msg, infoFile, ME.identifier, ME.message);
                end
                obj.machineName         = infoData.machineName;
                obj.resourceName        = infoData.resourceName;
                obj.resourceType        = infoData.resourceType;
                obj.userName            = infoData.userName;
                obj.password            = infoData.password;

                obj.requestedSimCoreName = '';
                obj.assignedSimCoreName = '';
                obj.numProcessors       = infoData.flavor.numProcessors;
                obj.coresPerProcessor   = infoData.flavor.coresPerProcessor;
                obj.RAM                 = infoData.flavor.RAM;
                obj.storage             = infoData.flavor.storage;
                imageFile               = infoData.image.file;
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
                obj.ipAddress           = imageData.ipAddress;
                obj.hostKeyFingerprint  = imageData.hostKeyFingerprint;

                obj.compilerDir         = imageData.matlab.compilerDir;
                obj.compiler            = imageData.matlab.compiler;
                obj.executable          = imageData.matlab.executable;
                obj.mcrDir              = imageData.matlab.mcrDir;
                obj.xCompDir            = imageData.matlab.xCompDir;
                obj.commsID             = '';
                obj.instanceName        = '';
%                 obj.uploadMachineConfig = struct;

                obj.simCores            = imageData.simCores; % Cell array
                % Need to check each simCore name to see if it is in SimCores.json
                % (not implemented yet)
            end
        end
    end
    
    % None of the sets works for some unknown reason - no error; they just
    % don't set.  The gets seem to work fine...
    methods (Sealed)
        % ---
        function name = getResourceName(obj)
            name = obj.resourceName;
        end
        
        % ---
        function id = getCommsID(obj)
            id = obj.commsID;
        end
        
        % ---
        function name = getInstanceName(obj)
            name = obj.instanceName;
        end
        
        % ---
        function type = getResourceType(obj)
            type = obj.resourceType;
        end
        
        % ---
        function name = getMachineName(obj)
            name = obj.machineName;
        end
        
        % ---
        function name = getUserName(obj)
            name = obj.userName;
        end
        
        % ---
        function pw = getPassword(obj)
            pw = obj.password;
        end
        
        % ---
        function ipAddress = getIpAddress(obj)
            ipAddress = obj.ipAddress;
        end
        
        % ---
        function fp = getHostKeyFingerprint(obj)
            fp = obj.hostKeyFingerprint;
        end
        
        % ---
        function num = getNumSimulators(obj)
            num = obj.numSimulators;
        end
        
        % ---
        function dir = getWorkDir(obj)
            dir = obj.workDir;
        end

        % ---
        function simCores = getSimCores(obj)
            simCores = obj.simCores;
        end
        
        % ---
        function name = getRequestedSimCoreName(obj)
            name = obj.requestedSimCoreName;
        end

%START HERE
        % ---
        function name = getAssignedSimCoreName(obj)
            name = obj.assignedSimCoreName;
        end
        
        % ---
        function num = getNumProcessors(obj)
            num = obj.numProcessors;
        end
        
        % ---
        function num = getNumCoresPerProcessor(obj)
            num = obj.numCoresPerProcessor;
        end
        
        % ---
        function ram = getRAM(obj)
            ram = obj.RAM;
        end
        
        % ---
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
        
%         function setResourceName(obj, name)
%             obj.resourceName = name;
%         end
%         function setResourceType(obj, type)
%             obj.resourceType = type;
%         end
%         function setMachineName(obj, name)
%             obj.machineName = name;
%         end
%         function setUserName(obj, name)
%             obj.userName = name;
%         end
%         function setIpAddress(obj, ipAddress)
%             obj.ipAddress = ipAddress;
%         end
%         function setNumSimulators(obj, num)
%             obj.numSimulators = num;
%         end
%         function setWorkDir(obj, dir)
%             obj.workDir = dir;
%         end
%         function setSimCoreName(obj, name)
%             obj.simCoreName = name;
%         end
%         function setNumCores(obj, num)
%             obj.numCores = num;
%         end
%         function setRAM(obj, ram)
%             obj.RAM = ram;
%         end
%         function setStorage(obj, storage)
%             obj.Storage = storage;
%         end
        
    end
end
