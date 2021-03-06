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
        ipAddress;
        fsIpAddress;
        jsIpAddress;
        simCores; % Cell array of all SimCores in the json file in use
        hostKeyFingerprint;
        numSimulators;
        workDir;
        acceptableSimCoreList;
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
        mcrVer;
        mcrDir;
        xCompDir;
        
        % raw input
        infoData;
        imageData;
    end
    
    methods (Abstract)
%         getSimCoreList(obj)
    end
    methods
        function obj = MachineConfig(infoFile)
            if (nargin==0 || isempty(infoFile))
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
                obj.acceptableSimCoreList = {};
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
                obj.mcrVer = '';
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
                    switch obj.infoData.resourceType
                        case 'STANDALONESERVER'
                            obj.resourceType = MachineType.STANDALONESERVER;
                        case 'CLOUDSERVER'
                            obj.resourceType = MachineType.CLOUDSERVER;
                        case 'SGECLUSTER'
                            obj.resourceType = MachineType.SGECLUSTER;
                        case 'SLURMCLUSTER'
                            obj.resourceType = MachineType.SLURMCLUSTER;
                        otherwise
                            error(['Infofile ' infoFile ' must specify valid resourceType. (not ' obj.infoData.resourceType ')']);
                    end 
                else
                    error(['Infofile ' infoFile ' must specify resourceType.']);
                end
                
                obj.acceptableSimCoreList = {};
                obj.assignedSimCoreName = '';

                try
                    obj.imageData = obj.infoData.images;
                catch ME
                    msg = ['Error processing %s. Possible syntax error.\n' ...
                           'Information given is: %s, %s.'];
                    error(msg, infoFile, ME.identifier, ME.message);
                end
                
%                 obj.ipAddress           = obj.imageData.ipAddress;
                if isfield(obj.imageData, 'hostKeyFingerprint')
                    obj.hostKeyFingerprint = strtrim(obj.imageData.hostKeyFingerprint);
                else
                    obj.hostKeyFingerprint = '';
                end

                obj.compilerDir         = obj.imageData.matlab.compilerDir;
                obj.compiler            = obj.imageData.matlab.compiler;
                obj.executable          = obj.imageData.matlab.executable;
                obj.mcrVer              = obj.imageData.matlab.mcrVer;
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
        function name = getMachineName(obj)
            name = obj.machineName;
        end
        
        % ---
        function name = getResourceName(obj)
            name = obj.resourceName;
        end
        
        % ---
        function type = getResourceType(obj)
            type = obj.resourceType;
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
        function list = getAcceptableSimCoreList(obj)
            list = obj.acceptableSimCoreList;
        end
        
        % ---
        function name = getAssignedSimCoreName(obj)
            name = obj.assignedSimCoreName;
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
        function num = getNumProcessors(obj)
            num = obj.numProcessors;
        end
        
        % ---
        function num = getCoresPerProcessor(obj)
            num = obj.coresPerProcessor;
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
        function ver = getMcrVer(obj)
            ver = obj.mcrVer;
        end
        
        % ---
        function dir = getMcrDir(obj)
            dir = obj.mcrDir;
        end
        
        % ---
        function dir = getXCompDir(obj)
            dir = obj.xCompDir;
        end        
        
        % ---
        function id = getCommsID(obj)
            id = obj.commsID;
        end
        
        % ---
        function tf = flavorCompatibilityCheck(obj, flavorMin)
            % This exact comparison is TEMPORARY
            numCores = obj.numProcessors * obj.coresPerProcessor;
            tf = ((flavorMin.numCores <= numCores) && ...
                  (flavorMin.RAM <= obj.RAM));
        end
        
        % -----
        function simCoreList = getSimCoreList(obj)
            simCoreList = {};
            for i = 1:length(obj.simCores)
                simCoreList = [simCoreList obj.simCores{i}.name]; %#ok<AGROW>
            end
        end

        % ---
        function name = findCompatibleSimCore(obj)
            name = '';
            supportedList = obj.getSimCoreList();
            for j = 1:length(obj.acceptableSimCoreList)
                for k = 1:length(supportedList)
                    if strcmp(obj.acceptableSimCoreList{j}, ...
                              supportedList{k})
                        name = supportedList{k};
                        return;
                    end
                end
            end
        end
    end
end
