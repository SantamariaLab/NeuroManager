classdef StandaloneCommsTest < MachineCommsTest
    methods
        function obj = StandaloneCommsTest(config, hostID, hostOS,...
                         hostScratchDir, ...
                         auth, log)
            targetBaseDir = config.getWorkDir();  % temp
            obj = obj@MachineCommsTest(config, hostID, hostOS,...
                              hostScratchDir, targetBaseDir, auth, log);
            obj.configureDualKey(config);
        end
    end
end