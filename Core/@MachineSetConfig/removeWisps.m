function removeWisps(obj)
% Removes the instances associated with all cloud servers in the
% machineSetConfig that have the isWisp property = true.
    for i = 1:obj.numMachines
        if strcmp(obj.MSConfig(i).resourceType, 'CLOUDSERVER')
            if obj.MSConfig(i).isWisp
                % Load up the cloud info to determine which constructor to use
                wispCloudInfo = loadjson(obj.MSConfig(i).cloudInfoFile);
                wispCloudType = CloudManagementType.(wispCloudInfo.cloudManagementType);
                cm = wispCloudType.constrFunc(obj.MSConfig(i).cloudInfoFile);
                wispID = cm.serverIdFromName(obj.MSConfig(i).instanceName);
                cm.deleteServerId(wispID);
            end
        end
    end
end
