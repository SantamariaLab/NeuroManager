% The MachineConfig class and subclasses gather data from various files
% and user parameters to supply NeuroManager with a unified group of data
% for machine setup and compatibility checking.

classdef MachineConfig < matlab.mixin.Heterogeneous  & dynamicprops
    properties 
        machineName;
        resourceName;
        resourceType;
        userName;
        fsUserName;
        jsUserName;
        password;
        fsPassword;
        jsPassword;
        simCores;
        ipAddress;
        fsIpAddress;
        jsIpAddress;
        hostKeyFingerprint;
        numSimulators;
        workDir;
        requestedSimCoreName;
        assignedSimCoreName;
        id;
        commsID;
        
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
        
        % raw input
        infoData;
        imageData;
    end
    
    methods
        function obj = MachineConfig(infoFile)
            if nargin==0
                obj.machineName = '';
                obj.resourceName = '';
                obj.resourceType = '';
                obj.userName = '';
                obj.fsUserName = '';
                obj.jsUserName = '';
                obj.password = '';
                obj.fsPassword = '';
                obj.jsPassword = '';
                obj.ipAddress = '';
                obj.jsIpAddress = '';
                obj.fsIpAddress = '';
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
            else
                % Pull in the infoFile (JSON format) and fill in the data
                % related to this class
                if ~exist(infoFile, 'file') == 2
                    error(['Error: NeuroManager could not find the file '...
                           infoFile ' during configuration processing.']);
                end
                try
                    obj.infoData = loadjson(infoFile);
                catch ME
                    msg = ['Error processing %s. Possible syntax error.\n' ...
                           'Information given is: %s, %s.'];
                    error(msg, infoFile, ME.identifier, ME.message);
                end
                
                if isfield(obj.infoData, 'resourceName')
                    obj.resourceName        = obj.infoData.resourceName;
                else
                    error(['Infofile ' infoFile ' must specify resourceName.']);
                end
                
                % NEED TO CHECK FOR VALID TYPE
                % (not implemented yet)
                if isfield(obj.infoData, 'resourceType')
                    obj.resourceType        = obj.infoData.resourceType;
                else
                    error(['Infofile ' infoFile ' must specify resourceType.']);
                end
                
%                 if isfield(obj.infoData, 'userName')
%                     obj.userName        = obj.infoData.userName;
%                 end
%                 if isfield(obj.infoData, 'fsUserName')
%                     obj.fsUserName      = obj.infoData.fsUserName;
%                 end
%                 if isfield(obj.infoData, 'jsUserName')
%                     obj.jsUserName      = obj.infoData.jsUserName;
%                 end
%                 obj.password            = obj.infoData.password;

                obj.requestedSimCoreName = '';
                obj.assignedSimCoreName = '';

                % Clusters have flavors buried in the queue and we do those
                % in the subclass.
%                 if isfield(obj.infoData, 'flavor')
%                     obj.numProcessors       = obj.infoData.flavor.numProcessors;
%                     obj.coresPerProcessor   = obj.infoData.flavor.coresPerProcessor;
%                     obj.RAM                 = obj.infoData.flavor.RAM;
%                     obj.storage             = obj.infoData.flavor.storage;
%                 end
                
                imageFile               = obj.infoData.image.file;
                if ~exist(imageFile, 'file') == 2
                    error(['Error: NeuroManager could not find the file '...
                           imageFile ' during configuration processing.']);
                end
                try
                    obj.imageData = loadjson(imageFile); 
                catch ME
                    msg = ['Error processing %s. Possible syntax error.\n' ...
                           'Information given is: %s, %s.'];
                    error(msg, imageFile, ME.identifier, ME.message);
                end
                
%                 obj.ipAddress           = obj.imageData.ipAddress;
                obj.hostKeyFingerprint  = obj.imageData.hostKeyFingerprint;

                obj.compilerDir         = obj.imageData.matlab.compilerDir;
                obj.compiler            = obj.imageData.matlab.compiler;
                obj.executable          = obj.imageData.matlab.executable;
                obj.mcrDir              = obj.imageData.matlab.mcrDir;
                obj.xCompDir            = obj.imageData.matlab.xCompDir;

                obj.simCores            = obj.imageData.simCores; % Cell array
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
        function name = getFsUserName(obj)
            name = obj.fsUserName;
        end
        
        % ---
        function name = getJsUserName(obj)
            name = obj.jsUserName;
        end
        
        % ---
        function pw = getPassword(obj)
            pw = obj.password;
        end
        
        % ---
        function pw = getFsPassword(obj)
            pw = obj.fsPassword;
        end
        
        % ---
        function pw = getJsPassword(obj)
            pw = obj.jsPassword;
        end
        
        % ---
        function ipAddress = getIpAddress(obj)
            ipAddress = obj.ipAddress;
        end
        
        % ---
        function ipAddress = getFsIpAddress(obj)
            ipAddress = obj.fsIpAddress;
        end
        
        % ---
        function ipAddress = getJsIpAddress(obj)
            ipAddress = obj.jsIpAddress;
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
