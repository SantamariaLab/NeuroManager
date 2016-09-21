classdef ClusterCommsTest < MachineCommsTest
    methods
        function obj = ClusterCommsTest(config, hostID, hostOS,...
                                        hostScratchDir, auth, log)
            targetBaseDir = config.getWorkDir();
            obj = obj@MachineCommsTest(config, hostID, hostOS,...
                              hostScratchDir, targetBaseDir, auth, log);
            obj.configureDualKey(config);
        end
    end
end