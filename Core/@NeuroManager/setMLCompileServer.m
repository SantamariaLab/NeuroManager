function setMLCompileServer(obj, varargin)
% Adds a (non-cloud) standalone server to the machine set.
% compDir must already exist on the target and preferably be
% empty. Assume that everything in the compDir will be deleted
% automatically. 
    if obj.machineSetType == SimType.UNASSIGNED
        error(['User must assign Simulator Type using the NeuroManager '...
               'class method setSimulatorType() before using this method.']);
    end

    p = inputParser();
    p.StructExpand = true;
    p.CaseSensitive = true;
    p.KeepUnmatched = false;

    addRequired(p, 'infoFile', @ischar);
%     addRequired(p, 'compDir', @(x) ischar(x) && ~isempty(x)); 
    parse(p, varargin{:});                              

    % The constructor checks for file existence
    obj.mLCompileConfig = MLCompileConfig(p.Results.infoFile);

    % Flavor and SimCore checks based on simulator type
%     simType = obj.machineSetType;
%     flavorMin = simType.flavorMin;
%     acceptableSimCoreList = simType.simCoreList;

    %DISABLE ALL compiler version CHECKING FOR NOW
    
%     if ~obj.MSConfig(i).flavorCompatibilityCheck(flavorMin)
%         error(['Flavor of ' obj.MSConfig(i).resourceName ...
%                ' is not sufficient for Simulator minimum.' ...
%                ' See SimType.m for Simulator minimums.']);
%     end
    
    % Check acceptableSimCoreList to see if there is at least one
    % in the SimCores data from the infoFile's image; the first one we find
    % becomes the assigned SimCore.
%     obj.MSConfig(i).acceptableSimCoreList = p.Results.acceptableSimCoreList;
%     obj.MSConfig(i).acceptableSimCoreList = acceptableSimCoreList;
%     obj.MSConfig(i).assignedSimCoreName = ...
%                                  obj.MSConfig(i).findCompatibleSimCore();
%     if isempty(obj.MSConfig(i).assignedSimCoreName)
%         error(['Could not find a compatible SimCore on ' ...
%                obj.MSConfig(i).getMachineName() '.']);
%     end

    % Now that we have assigned a SimCore, we must add its
    % properties to the config object in question:
% 	MachineSetConfig.ProcessSimCore(obj.MSConfig(i));
% MachineSetConfig.ProcessSimCore(obj.mLCompileConfig);  % What does this do?
%     obj.MSConfig(i).numSimulators = p.Results.numSimulators;

    % Need multiple checks on this; here and elsewhere IMPORTANT!!!
    % (not implemented yet)
%     obj.mLCompileConfig.workDir = p.Results.compDir;

    % SingleMachine configuration requires a positive number of
    % simulators
    obj.log.write(['Server ' obj.mLCompileConfig.resourceName ' added as the MLCompile server.']);
end
    