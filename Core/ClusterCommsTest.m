classdef ClusterCommsTest < MachineCommsTest
    methods
        function obj = ClusterCommsTest(config, hostID, hostOS,...
                         hostScratchDir, targetBaseDir,...
                         auth, log, ~)
%             md = dataFunc('','');
%             md.addSetting('id', [md.getSetting('resourceName')...
%                                  queueData.extension]);
%             md.addSetting('commsID', md.getSetting('resourceName'));

            obj = obj@MachineCommsTest(config, hostID, hostOS,...
                              hostScratchDir, targetBaseDir, auth, log);
            obj.configureDualKey(config);
        end
    end
end