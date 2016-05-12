function ProcessSimCore(configObject)
    
% Now that we have assigned a SimCore, we must add its
    % properties to this object:
    % -- get the type
    simCore = {};
    for j = 1:length(configObject.simCores)
        if strcmp(configObject.simCores{1,j}.name,...
                  configObject.assignedSimCoreName)
            simCore = configObject.simCores{1,j};
        end
    end
    if isempty(simCore)
        % Deal with errors here and in the rest of the file 
        % (not implemented yet)
    end

    % -- get the defined properties for that type
    typeFile = 'SimCoreTypes.json'; %#ok<CTPCT>
    try
        typeInfo = loadjson(typeFile);
    catch ME
        msg = ['Error processing %s. Possible syntax error.\n' ...
                   'Information given is: %s, %s.'];
        error(msg, typeFile, ME.identifier, ME.message);
    end
    
    simCoreType = {};
    for j = 1:length(typeInfo.SimCoreTypes)
        if strcmp(typeInfo.SimCoreTypes{1,j}.name, simCore.type)
            simCoreType = typeInfo.SimCoreTypes{1,j};
            break;
        end
    end
    if isempty(simCoreType)
        % Deal with errors here and in the rest of the file 
        % (not implemented yet)
    end

    % -- add the type's properties to this object
    % -- and copy from the struct to this object 
    % -- also assemble the uploadData struct for ship to remote
    numProps = length(simCoreType.properties);
    for j = 1:numProps
        configObject.addprop(simCoreType.properties{j});
        configObject.(simCoreType.properties{j}) = ...
                        simCore.config.(simCoreType.properties{j});
    end

end
