% CloudManagement provides the basic interface that subclasses must make
% happen. NeuroManager uses these methods only.  Note: this is not a
% general-purpose SDK for clouds; it has only been developed for use in
% NeuroManager.
classdef CloudManagement < handle
    methods (Abstract)
        createServerWait(obj)
        createServerNoWait(obj)
        serverWaitTillReady(obj)
        attachIpNewServer(obj)
        createMultipleServersNoWait(obj)
        multipleServersWaitTillReady(obj)
        multipleNewServersAttachIp(obj)
        deleteServerId(obj)
        deleteMultipleServers(obj)
        getServerDataId(obj)
        listImages(obj)
        listFlavors(obj)
        listNetworks(obj)
        listServers(obj)
        listKeyPairs(obj)
        numAvailableServerSlots(obj)
        existsServerId(obj)
        existsServerName(obj)
        serverIdFromName(obj)
        serverNameFromId(obj)
        existsImageName(obj)
        existsFlavorName(obj)
        existsNetworkName(obj)
        existsKeyPairName(obj)
        getQuotas(obj)
    end
end