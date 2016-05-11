% -----------
function addClusterQueue(obj, varargin)
% Builds a cluster config and finishes filling it in with knowledge
% of the other inputs, and adds it to the machine set. Parameters
% are, in order: SimCore, infoFile, queueName, number of simulators, 
% basedir. Optional parameters: wallclocktime,....   
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

    defaultWallClockTime = '00:00:00';
    defaultParEnvStr = '';
    defaultResourceStr = '';
    defaultNumNodes = 1; % This parameter is suspect

    addRequired(p, 'requestedSimCoreName', @ischar);
    addRequired(p, 'infoFile', @ischar);
    addRequired(p, 'queueName', @ischar); 
    addRequired(p, 'numSimulators', @(x) isnumeric(x) && x>=0);
    % Check for basedir existence is elsewhere since it is remote
    % and needs machine object for communications.
    addRequired(p, 'workDir', @(x) ischar(x) && ~isempty(x)); 

    addParamValue(p, 'wallClockTime', defaultWallClockTime,...
                                  @(x) regexp(x,'^\d\d:\d\d:\d\d$')); %#ok<*NVREPL>
    addParamValue(p, 'parEnvStr', defaultParEnvStr,...
                                  @ischar); %#ok<*NVREPL>
    addParamValue(p, 'resourceStr', defaultResourceStr,...
                                    @ischar); %#ok<*NVREPL>
    addParamValue(p, 'numNodes', defaultNumNodes, @isnumeric);
    parse(p, varargin{:});                              

    i = obj.numMachines+1;
    obj.MSConfig(i) = ClusterConfig(p.Results.infoFile);
    
    obj.MSConfig(i).wallClockTime = p.Results.wallClockTime;
    obj.MSConfig(i).parEnvStr = p.Results.parEnvStr;
    obj.MSConfig(i).resourceStr = p.Results.resourceStr;
    obj.MSConfig(i).numNodes = p.Results.numNodes;
    
    % ++++ Queue Processing
    % Pull out the queue info for the requested queue
    queueData = {};
    for j = 1:length(obj.MSConfig(i).queues)
        if strcmp(obj.MSConfig(i).queues{1,j}.name, p.Results.queueName)
            queueData = obj.MSConfig(i).queues{1,j};
            break;
        end
    end
    if isempty(queueData)
        error(['Requested queue ' p.Results.queueName ' not found in file '...
               infoFile '.']);
    end

    % Do these here because we now know the queue name
    obj.MSConfig(i).machineName = [obj.MSConfig(i).resourceName ...
                                   queueData.name];
	obj.MSConfig(i).id  = obj.MSConfig(i).machineName;
    obj.MSConfig(i).commsID = obj.MSConfig(i).resourceName;
    
    if isfield(queueData, 'queueString')
         obj.MSConfig(i).queueString = queueData.queueString;
    else
        error(['Infofile ' infoFile ...
               'queue entries must specify queueString.']);
    end

    if isfield(queueData, 'flavor')
        obj.MSConfig(i).numProcessors       = queueData.flavor.numProcessors;
        obj.MSConfig(i).coresPerProcessor   = queueData.flavor.coresPerProcessor;
        obj.MSConfig(i).RAM                 = queueData.flavor.RAM;
        obj.MSConfig(i).storage             = queueData.flavor.storage;
    else
        error(['Infofile ' infoFile 'queue entries must specify flavor.']);
    end

    % ++++ SimCore Processing
    % Need to check requestedSimCoreName to see if it is in
    % SimCores.json and in the SimCores data from the infoFile
    % (not implemented yet)

    %  Also need to be able to assign a different, yet compatible
    %  SimCore; for now we just do a simple pass-through
    obj.MSConfig(i).requestedSimCoreName = ...
                                p.Results.requestedSimCoreName;
    obj.MSConfig(i).assignedSimCoreName = ...
                                obj.MSConfig(i).requestedSimCoreName;

    obj.MSConfig(i).numSimulators = p.Results.numSimulators;

    % Now that we have assigned a SimCore, we add its
    % properties to the config object in question:
    MachineSetConfig.ProcessSimCore(obj.MSConfig(i));

    % Need multiple checks on this; here and elsewhere IMPORTANT!!!
    % (not implemented yet)
    obj.MSConfig(i).workDir = p.Results.workDir;
    obj.numMachines = i;

    % SingleMachine configuration requires a positive number of
    % simulators
    if (obj.singleMachine && (obj.MSConfig(i).numSimulators <= 0))
        error(['MachineSetConfig error: Single machine '... 
               'setup requires at least one simulator.']);
    end    
    obj.log.write(['Cluster ' obj.MSConfig(i).resourceName ...
                   ' queue ' obj.MSConfig(i).queueString ...
                   ' added to Machine Set Configuration as ' ...
                   obj.MSConfig(i).machineName '.']);

end
