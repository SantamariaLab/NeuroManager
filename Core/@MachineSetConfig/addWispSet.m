function addWispSet(obj, varargin)
% Creates a wispSet (ephemeral cloud server bank) on the cloud on question,
% then adds the cloud servers to the machine set.

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

    addRequired(p, 'numWisps', @(x) isnumeric(x) && x>=0);
    addRequired(p, 'wispNameRoot', @ischar);
    addRequired(p, 'wispInfoFile', @ischar);
    addRequired(p, 'simulatorType', @ischar);
    addRequired(p, 'numSimulators', @(x) isnumeric(x) && x>=0);
    % Check for workdir existence is elsewhere since it is remote
    % and needs machine object for communications.
    addRequired(p, 'workDir', @(x) ischar(x) && ~isempty(x)); 
    parse(p, varargin{:}); 
    
    numWisps                = p.Results.numWisps;
    wispNameRoot            = p.Results.wispNameRoot;
    wispInfoFile            = p.Results.wispInfoFile;
    simulatorType           = p.Results.simulatorType;
    numSimulators           = p.Results.numSimulators;
    workDir                 = p.Results.workDir;
    
    % load up the wisp info and construct the cloud manager so we can build
    % the wisp
    try 
        wispInfo = loadjson(wispInfoFile);
    catch ME
        msg = ['Error processing %s. Possible syntax error.\n' ...
                   'Information given is: %s, %s.'];
        error(msg, imageFile, ME.identifier, ME.message);
    end
    cloudInfoFileName   = wispInfo.cloudInfoFile;
    imageName           = wispInfo.imageName;
    flavorName          = wispInfo.flavorName;
    networkName         = wispInfo.networkName;

    % Load up the cloud info to determine which constructor to use
    try 
        cloudInfo = loadjson(cloudInfoFileName);
    catch ME
        msg = ['Error processing %s. Possible syntax error.\n' ...
                   'Information given is: %s, %s.'];
        error(msg, imageFile, ME.identifier, ME.message);
    end
    requestedCloudType = cloudInfo.cloudManagementType;
    try
        actualCloudType = CloudManagementType.(requestedCloudType);
    catch ME
        msg = ['Error processing %s. Invalid Cloud Type.\n' ...
               'Check CloudManagementType.m for valid types '...
               '(add new types if necessary).\n' ...
                   'Information given is: %s, %s.'];
        error(msg, cloudInfoFileName, ME.identifier, ME.message);
    end
    
    % Construct the cloud management object
    cm = actualCloudType.constrFunc(cloudInfoFileName);
    
    % Create the list of names and ipAddresses
    wispNameList = {};
    for i = 1:numWisps
        wispNameList = [wispNameList [wispNameRoot num2str(i,'%02u')]]; %#ok<AGROW>
    end
    
    % Check for preexistence of the requested wisps (not allowed)
    for i = 1:numWisps
        if ~isempty(cm.serverIdFromName(wispNameList{i}))
            error(['Server ' wispNameList{i} ' already exists. '...
                   ' Use the addCloudServer method instead.']);
        end
    end
    
    % Check for valid image, flavor, and network
    if ~cm.existsImageName(imageName)
        error(['Image ' imageName ...
               ' does not exist on this cloud/tenant.']);
    end
    if ~cm.existsFlavorName(flavorName)
        error(['Flavor ' flavorName ...
               ' does not exist on this cloud/tenant.']);
    end
    if ~isempty(networkName)
        if ~cm.existsNetworkName(networkName)
            error(['Network ' networkName ...
                   ' does not exist on this cloud/tenant.']);
        end
    end
    
    % Check compatibilities before taking time to construct
    % instances. Use a patched-together config
    tempConfig = CloudConfig('');
    tempConfig.cloudInfoFile = cloudInfoFileName;
    tempConfig.infoData = cloudInfo;
    requestedImage = wispInfo.imageName;
    imageLocated = false;
    for j = 1:length(cloudInfo.images)
        if strcmp(cloudInfo.images{j}.name, requestedImage)
            tempConfig.imageData = cloudInfo.images{j};
            imageLocated = true;
            break;
        end
    end
    if ~imageLocated
        error(['Requested image ' imageName ' not found in info file ' ...
               cloudInfoFileName '.']);
    end
    
    % Pick out the desired flavor and stick it in here
    requestedFlavor = wispInfo.flavorName;
    flavorLocated = false;
    for j = 1:length(cloudInfo.flavors)
        if strcmp(cloudInfo.flavors{j}.name, requestedFlavor)
            tempConfig.numProcessors = ...
                                 cloudInfo.flavors{j}.numProcessors;
            tempConfig.coresPerProcessor = ...
                                 cloudInfo.flavors{j}.coresPerProcessor;
            tempConfig.RAM        = cloudInfo.flavors{j}.RAM;
            tempConfig.storage    = cloudInfo.flavors{j}.storage;
            flavorLocated = true;
            break;
        end
    end
    if ~flavorLocated
        error(['Requested flavor ' flavorName ' not found in info file ' ...
               cloudInfoFileName '.']);
    end    

    % Flavor check based on simulator type
    simType = SimType.(simulatorType);
    if ~isenum(simType)
        error([simulatorType ' is not a valid Simulator Type. ' ...
               ' See SimType.m for types that have been defined.']);
    end
    flavorMin = simType.flavorMin;

    if ~tempConfig.flavorCompatibilityCheck(flavorMin)
        error(['Flavor of ' wispNameRoot ...
               ' is not sufficient for Simulator minimum.' ...
               ' See SimType.m for Simulator minimums.']);
    end

    tempConfig.acceptableSimCoreList = simType.simCoreList;
    tempConfig.simCores = tempConfig.imageData.simCores;
    tempConfig.assignedSimCoreName = tempConfig.findCompatibleSimCore();
    if isempty(tempConfig.assignedSimCoreName)
        error(['Could not find a compatible SimCore on ' ...
               tempConfig.getMachineName() '.']);
    end
    % Save the chosen SimCoreName for constructing each wisp in the set
    assignedSimCoreName = tempConfig.assignedSimCoreName;
    delete(tempConfig);

    % All ok so create the instances
	obj.log.write(['Creating WispSet ' wispNameRoot ' on ' ...
                   cloudInfo.cloudManagementType '.']);
    wispList = ...
        cm.createMultipleServersNoWait(numWisps,... 
                                       wispNameRoot, imageName, ...
                                       flavorName, networkName);
    cm.multipleServersWaitTillReady(wispList);
    cm.multipleNewServersAttachIp(wispList);
            %     [serverName, serverId] = ...
            %         cm.createServerWait(wispName, imageName, flavorName, networkName);
            % ipAddr = cm.attachIpNewServer(serverId);
            %     [~, ~, ipAddr] = cm.getServerDataId(serverId);
	obj.log.write(['WispSet ' wispNameRoot ' created on ' ...
                   cloudInfo.cloudManagementType '.']);
    
	% Now add each wisp to the config, one at a time
    % This is not an optimal approach but is the quickest to implementation
    for k = 1:numWisps
        i = obj.numMachines+1;
        obj.MSConfig(i) = CloudConfig('');

        % individual-wisp-specific stuff here
        obj.MSConfig(i).instanceName = wispList{k}.name;
        [~, ~, ipAddrSet] = cm.getServerDataId(wispList{k}.id);
        obj.MSConfig(i).ipAddress = ipAddrSet{1}.address;

        % common to all wisps in the set 
        % (so need a better implementation -- not implemented yet)
        % Create a blank config and fill it in here rather from a single static
        % server info file
        obj.MSConfig(i).isWisp = true;
        obj.MSConfig(i).cloudInfoFile = cloudInfoFileName;
        obj.MSConfig(i).infoData = cloudInfo;
        obj.MSConfig(i).resourceName = cloudInfo.resourceName;
        obj.MSConfig(i).resourceType = wispInfo.resourceType;
        % Pick out the desired image and stick it in here
        requestedImage = wispInfo.imageName;
        imageLocated = false;
        for j = 1:length(cloudInfo.images)
            if strcmp(cloudInfo.images{j}.name, requestedImage)
                obj.MSConfig(i).imageData = cloudInfo.images{j};
                imageLocated = true;
                break;
            end
        end
        if ~imageLocated
            error(['Requested image ' imageName ' not found in info file ' ...
                   cloudInfoFileName '.']);
        end
        % All wisps in the set have the same hostKeyFingerprint
        obj.MSConfig(i).hostKeyFingerprint = ...
                            obj.MSConfig(i).imageData.hostKeyFingerprint;
        obj.MSConfig(i).compilerDir = ...
                            obj.MSConfig(i).imageData.matlab.compilerDir;
        obj.MSConfig(i).compiler = ...
                            obj.MSConfig(i).imageData.matlab.compiler;
        obj.MSConfig(i).executable = ...
                            obj.MSConfig(i).imageData.matlab.executable;
        obj.MSConfig(i).mcrDir = obj.MSConfig(i).imageData.matlab.mcrDir;
        obj.MSConfig(i).xCompDir = obj.MSConfig(i).imageData.matlab.xCompDir;
        obj.MSConfig(i).simCores = obj.MSConfig(i).imageData.simCores;
        obj.MSConfig(i).userName = obj.MSConfig(i).imageData.user;
        obj.MSConfig(i).password = obj.MSConfig(i).imageData.password;

        obj.MSConfig(i).fsUserName = obj.MSConfig(i).userName;
        obj.MSConfig(i).jsUserName = obj.MSConfig(i).userName;
        obj.MSConfig(i).fsPassword = obj.MSConfig(i).password;
        obj.MSConfig(i).jsPassword = obj.MSConfig(i).password;
        obj.MSConfig(i).fsIpAddress = obj.MSConfig(i).ipAddress;
        obj.MSConfig(i).jsIpAddress = obj.MSConfig(i).ipAddress;

        obj.MSConfig(i).machineName = obj.MSConfig(i).instanceName;
        obj.MSConfig(i).id = obj.MSConfig(i).machineName;
        obj.MSConfig(i).commsID = obj.MSConfig(i).instanceName;

        obj.MSConfig(i).numSimulators = numSimulators;

        % Now that we have assigned a SimCore, we must add its
        % properties to the config object in question:
        obj.MSConfig(i).assignedSimCoreName = assignedSimCoreName;
        MachineSetConfig.ProcessSimCore(obj.MSConfig(i));

        % Need multiple checks on this; here and elsewhere IMPORTANT!!!
        obj.MSConfig(i).workDir = workDir;
        obj.numMachines = i;

        % SingleMachine configuration requires a positive number of
        % simulators
        if (obj.singleMachine && (obj.MSConfig(i).numSimulators <= 0))
            error(['MachineSetConfig error: Single machine '... 
                   'setup requires at least one simulator.']);
        end  
        obj.log.write(['Wisp ' obj.MSConfig(i).instanceName ...
                       ' added to Machine Set Configuration.']);
    end
end
