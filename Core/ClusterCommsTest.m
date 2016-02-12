classdef ClusterCommsTest < MachineCommsTest
    methods
        function obj = ClusterCommsTest(hostID, hostOS,...
                         hostScratchDir, targetBaseDir,...
                         auth, log, ~, ~, dataFunc, queueData)
            md = dataFunc('','');
            md.addSetting('id', [md.getSetting('resourceName')...
                                 queueData.extension]);
            md.addSetting('commsID', md.getSetting('resourceName'));

            obj = obj@MachineCommsTest(md, hostID, hostOS,...
                              hostScratchDir, targetBaseDir, auth, log);
            obj.configureDualKey();
        end
    end
end