function addWisp(obj, varargin)
% Creates a wisp (ephemeral cloud server) on the cloud on question, then
% adds the cloud server to the machine set.

    % If adding a second machine to a single machine config, is a
    % fatal error, even if the number of simulators is zero.
    if (obj.singleMachine && (obj.numMachines > 0))
        error(['MachineSetConfig error: Attempt to '...
               'add a second machine to a single machine setup.']);
    end

    p = inputParser();
    p.StructExpand = true;
    p.CaseSensitive = true;
    p.KeepUnmatched = false;

%     defaultDeleteInstanceWhenDone = false;

    addRequired(p, 'wispName', @ischar);
    addRequired(p, 'wispInfoFile', @ischar);
    addRequired(p, 'requestedSimCoreName', @ischar);
    addRequired(p, 'numSimulators', @(x) isnumeric(x) && x>=0);
    % Check for workdir existence is elsewhere since it is remote
    % and needs machine object for communications.
    addRequired(p, 'workDir', @(x) ischar(x) && ~isempty(x)); 
%     addParamValue(p, 'deleteInstanceWhenDone', ...
%                      defaultDeleteInstanceWhenDone, @islogical);
    parse(p, varargin{:}); 
    
    wispName = p.Results.wispName;
    % load up the wisp info and construct the cloud manager so we can build
    % the wisp
    try 
        wispInfo = loadjson(p.Results.wispInfoFile);
    catch ME
        msg = ['Error processing %s. Possible syntax error.\n' ...
                   'Information given is: %s, %s.'];
        error(msg, imageFile, ME.identifier, ME.message);
    end
    cloudInfoFileName = wispInfo.cloudInfoFileName;
    imageName = wispInfo.imageName;
    flavorName = wispInfo.flavorName;
    networkName = wispInfo.networkName;

    % Load up the cloud info to determine which constructor to use
    try 
        cloudInfo = loadjson(cloudInfoFileName);
    catch ME
        msg = ['Error processing %s. Possible syntax error.\n' ...
                   'Information given is: %s, %s.'];
        error(msg, imageFile, ME.identifier, ME.message);
    end
    requestedCloudType = cloudInfo.type;
    try
        actualCloudType = CloudManagementType.(requestedCloudType);
    catch ME
        msg = ['Error processing %s. Invalid Cloud Type.\n' ...
               'Check CloudManagementType.m for valid types (add new types if necessary).\n' ...
                   'Information given is: %s, %s.'];
        error(msg, cloudInfoFileName, ME.identifier, ME.message);
    end
    
    % Construct the cloud management object
    cm = actualCloudType.constrFunc(cloudInfoFileName);
    
    % Check for preexistence of the requested wisp (not allowed)
    if ~isempty(cm.serverIdFromName(wispName))
        error(['Server ' wispName ' already exists.  Use the addCloudServer method instead.']);
    end
    
    % Check for valid image, flavor, and network
    if ~cm.existsImageName(imageName)
        error(['Image ' imageName ' does not exist on this cloud/tenant.']);
    end
    if ~cm.existsFlavorName(flavorName)
        error(['Flavor ' flavorName ' does not exist on this cloud/tenant.']);
    end
    if ~cm.existsNetworkName(networkName)
        error(['Network ' networkName ' does not exist on this cloud/tenant.']);
    end
    
    % All ok for creating the instance
    [serverName, serverId] = ...
        cm.createServer(wispName, imageName, flavorName, networkName);
    
    
    #START HERE 
%     Rework info files for cloud and wisp both.  "Image" isn't 
%     used properly, and probably flavor should be named rather than details 
%     in the files like AutoBotInfo.json which are specific to an instance. If
%     the details are necessary than we can get them from the cloud info
%     file.  One point of definition...  User must request flavor, etc by
%     name. Also ImageAutoBot.json... what is that?  Is the word image used
%     properly there? probably not.  what I need is an image file that
%     describes the CC-CentOS7-to-MCRNEURON image, with its supported
%     SimCores, etc. then the dbs-test02 info file refers to that image
%     file, not the way things are right now.

    
    % Create a temporary info file for the new server that acts like a
    % cloud config file
    wispInfoFilePath = fullfile(obj.machineScratchDir, [wispName '_Info.json']);
    wispInfo.instanceName = wispName;
    wispInfo.resourceName = 
    wispInfo.resourceType = 'CLOUDSERVER';
    wispInfo.cloudInfoFile = cloudInfoFileName; % location?
    wispInfo.userName = 
    wispInfo.password = '';
    wispInfo.image = struct('file', imageName, 'buildscript', '');
    wispInfo.flavor = struct('numProcessors', xxxx,...
                             'coresPerProcessor', xxxx,...
                             'RAM', xxxx,...
                             'storage', xxxx);
	
    
    i = obj.numMachines+1;
    % The constructor checks for cloud infoFile existence
    obj.MSConfig(i) = CloudConfig(p.Results.infoFile);

    %  Also need to be able to assign a different, yet compatible
    %  SimCore; for now we just do a simple pass-through
    obj.MSConfig(i).requestedSimCoreName = ...
                                p.Results.requestedSimCoreName;
    obj.MSConfig(i).assignedSimCoreName = ...
                                obj.MSConfig(i).requestedSimCoreName;

    obj.MSConfig(i).numSimulators = p.Results.numSimulators;

    % Now that we have assigned a SimCore, we must add its
    % properties to the config object in question:
	MachineSetConfig.ProcessSimCore(obj.MSConfig(i));

    % Need multiple checks on this; here and elsewhere IMPORTANT!!!
    obj.MSConfig(i).workDir = p.Results.workDir;
    obj.numMachines = i;

    % SingleMachine configuration requires a positive number of
    % simulators
    if (obj.singleMachine && (obj.MSConfig(i).numSimulators <= 0))
        error(['MachineSetConfig error: Single machine '... 
               'setup requires at least one simulator.']);
    end  



end