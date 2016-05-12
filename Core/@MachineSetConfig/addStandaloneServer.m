% -----------
function addStandaloneServer(obj, varargin)
% Adds a (non-cloud) standalone server to the machine set.
% Parameters are, in order: type, number of simulators, name, data
% function, basedir, and wallclocktime.   
% Basedir must already exist on the target and preferably be
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

    addRequired(p, 'acceptableSimCoreList', @iscell);
    addRequired(p, 'infoFile', @ischar);
    addRequired(p, 'numSimulators', @(x) isnumeric(x) && x>=0);
    % Check for basedir existence is elsewhere since it is remote
    % and needs machine object for communications.
    addRequired(p, 'workDir', @(x) ischar(x) && ~isempty(x)); 
    parse(p, varargin{:});                              

    i = obj.numMachines + 1;
    % The constructor checks for file existence
    obj.MSConfig(i) = StandaloneConfig(p.Results.infoFile);

    % Check acceptableSimCoreList to see if there is at least one
    % in the SimCores data from the infoFile's image; the first one we find
    % becomes the assigned SimCore.
    obj.MSConfig(i).acceptableSimCoreList = p.Results.acceptableSimCoreList;
    obj.MSConfig(i).assignedSimCoreName = ...
                                 obj.MSConfig(i).findCompatibleSimCore();
    if isempty(obj.MSConfig(i).assignedSimCoreName)
        error(['Could not find a compatible SimCore on ' ...
               obj.MSConfig(i).getMachineName() '.']);
    end

    % Now that we have assigned a SimCore, we must add its
    % properties to the config object in question:
	MachineSetConfig.ProcessSimCore(obj.MSConfig(i));

    obj.MSConfig(i).numSimulators = p.Results.numSimulators;

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
    obj.log.write(['Standalone Server ' obj.MSConfig(i).resourceName ' added to Machine Set Configuration.']);
end
    