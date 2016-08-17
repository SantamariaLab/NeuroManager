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

    addRequired(p, 'wispName', @ischar);
    addRequired(p, 'wispInfoFile', @ischar);
    addRequired(p, 'simulatorType', @(x) isa(x, 'SimType'));
    addRequired(p, 'numSimulators', @(x) isnumeric(x) && x>=0);
    % Check for workdir existence is elsewhere since it is remote
    % and needs machine object for communications.
    addRequired(p, 'workDir', @(x) ischar(x) && ~isempty(x)); 
    parse(p, varargin{:}); 
    
    wispName                = p.Results.wispName;
    wispInfoFile            = p.Results.wispInfoFile;
    simType           = p.Results.simulatorType;
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
    cm = actualCloudType.constrFunc(cloudInfoFileName, ...
                                    obj.curlDir, ...
                                    obj.auth.getKeyFile());
    
    % Check for preexistence of the requested wisp (not allowed)
    if ~isempty(cm.serverIdFromName(wispName))
        error(['Server ' wispName ' already exists. '...
               ' Use the addCloudServer method instead.']);
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
    
    % Create a blank config so we can do the compatibility checks
    i = obj.numMachines+1;
    obj.MSConfig(i) = CloudConfig('');
    obj.MSConfig(i).isWisp = true;
	obj.MSConfig(i).cloudInfoFile = cloudInfoFileName;
    obj.MSConfig(i).infoData = cloudInfo;
    obj.MSConfig(i).resourceName = cloudInfo.resourceName;
    obj.MSConfig(i).resourceType = MachineType.CLOUDSERVER;
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
    % Pick out the desired flavor and stick it in here
    requestedFlavor = wispInfo.flavorName;
    flavorLocated = false;
    for j = 1:length(cloudInfo.flavors)
        if strcmp(cloudInfo.flavors{j}.name, requestedFlavor)
            obj.MSConfig(i).numProcessors = ...
                                 cloudInfo.flavors{j}.numProcessors;
            obj.MSConfig(i).coresPerProcessor = ...
                                 cloudInfo.flavors{j}.coresPerProcessor;
            obj.MSConfig(i).RAM        = cloudInfo.flavors{j}.RAM;
            obj.MSConfig(i).storage    = cloudInfo.flavors{j}.storage;
            flavorLocated = true;
            break;
        end
    end
    if ~flavorLocated
        error(['Requested flavor ' flavorName ' not found in info file ' ...
               cloudInfoFileName '.']);
    end
    
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
    obj.MSConfig(i).fsUserName = obj.MSConfig(i).userName;
    obj.MSConfig(i).jsUserName = obj.MSConfig(i).userName;
    obj.MSConfig(i).fsPassword = obj.MSConfig(i).password;
    obj.MSConfig(i).jsPassword = obj.MSConfig(i).password;
    obj.MSConfig(i).password = obj.MSConfig(i).imageData.password;
    obj.MSConfig(i).numSimulators = numSimulators;

    % Flavor and SimCore checks based on simulator type
    flavorMin = simType.flavorMin;
    acceptableSimCoreList = simType.simCoreList;
    
    if ~obj.MSConfig(i).flavorCompatibilityCheck(flavorMin)
        error(['Flavor of ' obj.MSConfig(i).resourceName ...
               ' is not sufficient for Simulator minimum.' ...
               ' See SimType.m for Simulator minimums.']);
    end
    
    % Check acceptableSimCoreList to see if there is at least one
    % in the SimCores data from the infoFile's image; the first one we find
    % becomes the assigned SimCore.
    obj.MSConfig(i).acceptableSimCoreList = acceptableSimCoreList;
    obj.MSConfig(i).assignedSimCoreName = ...
                                 obj.MSConfig(i).findCompatibleSimCore();
    if isempty(obj.MSConfig(i).assignedSimCoreName)
        error(['Could not find a compatible SimCore on ' ...
               obj.MSConfig(i).getMachineName() '.']);
    end

    % Now that we have assigned a SimCore, we must add its
    % properties to the config object in question:
	MachineSetConfig.ProcessSimCore(obj.MSConfig(i));
    
    % All ok so create the instance
	obj.log.write(['Creating Wisp ' wispName ' on cloud ' ...
                   cloudInfo.resourceName ' with SimCore ' ...
                   obj.MSConfig(i).assignedSimCoreName '.']);
    [serverName, serverId] = ...
        cm.createServerWait(wispName, imageName, flavorName, networkName);
    ipAddr = cm.attachIpNewServer(serverId);
	obj.log.write(['Wisp ' wispName ' created on cloud ' ...
                   cloudInfo.resourceName ' with IP Address '... 
                   ipAddr '.']);
       
    % Now the instance is available, can fill in the rest of the config 
    obj.MSConfig(i).instanceName = serverName;
    obj.MSConfig(i).machineName = obj.MSConfig(i).instanceName;
    obj.MSConfig(i).id = obj.MSConfig(i).machineName;
    obj.MSConfig(i).commsID = obj.MSConfig(i).instanceName;
    obj.MSConfig(i).ipAddress = ipAddr;
    obj.MSConfig(i).fsIpAddress = obj.MSConfig(i).ipAddress;
    obj.MSConfig(i).jsIpAddress = obj.MSConfig(i).ipAddress;


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
