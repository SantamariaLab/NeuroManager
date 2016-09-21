
function setMLCompileServer(obj, varargin)
% xCompDir must already exist on the target and have no subdirectories.
% Assume that everything in the xCompDir will be deleted automatically. 
    if obj.machineSetType == SimType.UNASSIGNED
        error(['User must assign Simulator Type using the NeuroManager '...
               'class method setSimulatorType() before using this method.']);
    end

    p = inputParser();
    p.StructExpand = true;
    p.CaseSensitive = true;
    p.KeepUnmatched = false;

    addRequired(p, 'infoFile', @ischar);
    parse(p, varargin{:});                              

    % The constructor checks for file existence
    obj.mLCompileConfig = MLCompileConfig(p.Results.infoFile);

    obj.log.write(['Server ' obj.mLCompileConfig.resourceName ...
                   ' added as the MLCompile server.']);
end
    