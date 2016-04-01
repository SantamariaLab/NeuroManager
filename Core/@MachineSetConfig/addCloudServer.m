% -----------
function addCloudServer(obj, varargin)
% Adds an existing cloud machine to the machine set. Parameters are, in
% order: type, number of simulators, name, data function, basedir,
% and wallclocktime.   
% Basedir  must already exist on the target and preferably be
% empty. Assume that everything in the basedir will be deleted
% automatically. Wallclocktime is a string in hh:mm:ss format;
% 00:00:00 or empty string indicates there is to be no timelimit on
% the job. 
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

    addRequired(p, 'requestedSimCoreName', @ischar);
    addRequired(p, 'infoFile', @ischar);
    addRequired(p, 'numSimulators', @(x) isnumeric(x) && x>=0);
    % Check for workdir existence is elsewhere since it is remote
    % and needs machine object for communications.
    addRequired(p, 'workDir', @(x) ischar(x) && ~isempty(x)); 
%     addParamValue(p, 'deleteInstanceWhenDone', ...
%                      defaultDeleteInstanceWhenDone, @islogical);
    parse(p, varargin{:}); 

    i = obj.numMachines+1;
    % The constructor checks for infoFile existence
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
if 0
    % We create a temporary CloudInstance object that provides the
    % tools to interrogate the instance in question. If there is no
    % such instance, it creates it for us.   
    % Creating the instance overrides all data set above.
    % Similarly, data pulled from an existing instance overrides
    % data from the script addCloudServer line. 
    if obj.MSConfig(i).numSimulators ~= 0
        if ~isempty(obj.MSConfig(i).machineName)
            obj.log.write(['Connecting to or attempting to launch instance '...
                           obj.MSConfig(i).machineName]);
        else
            obj.log.write(['Attempting to launch ephemeral instance;'...
                           'name to be determined automatically.']);
        end

        % Launching instances requires a local keyfile path and the
        % location of the cURL executable to be passed to the
        % instance management code
        obj.MSConfig(i).keyFile = obj.auth.getKeyFile();
        obj.MSConfig(i).curlDir = obj.curlDir;

        % Try to get rid of this switch somehow
        switch obj.MSConfig(i).resourceName
            case 'Chameleon'
                obj.MSConfig(i).instance = ...
                    CCCloudInstance(obj.MSConfig(i).machineName,...
                                    obj.MSConfig(i).imageRef,...
                                    obj.MSConfig(i).flavorRef);
            case 'Rackspace'
                config = obj.MSConfig(i);
                obj.MSConfig(i).instance = ...
                    RSCloudInstance(config);
%                             RSCloudInstance(obj.MSConfig(i).machineName,...
%                                             obj.MSConfig(i).imageRef,...
%                                             obj.MSConfig(i).flavorRef);
            otherwise
                error(['MachineSetConfig: unknown resource '...
                      obj.MSConfig(i).resourceName])
        end
        [~, name, ~, ipAddress] = obj.MSConfig(i).instance.getData();
        obj.MSConfig(i).machineName = name;
        obj.MSConfig(i).ipAddress = ipAddress;
        % HAVE TO DEAL WITH BASE DIR as parameter with default
        % since it is actually part of the image used to create the
        % instance. (etc)

        obj.log.write(['Instance ' obj.MSConfig(i).machineName ' ready.']);
%                 assignin('base', 'details', instance.getDetails())  % debug only

    end
end
    % Now we create a temporary FileTransferMachine in order to
        % get the host key fingerprint.  Currently the SSH library
        % doesn't care about the host key but PuTTY does, and will
        % cause a comms test failure. In order 
        % to assure PuTTY we have to run commands on the host and
        % download a file to get the host key fingerprint - using
        % the SSH library (this appears to be a bit of a loophole
        % but I don't yet know how to do this all automatically any
        % other way).
%                 tempMachine = FileTransferMachine(md, 
end