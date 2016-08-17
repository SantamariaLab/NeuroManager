classdef MLCompileCommsTest < MachineCommsTest
    methods
        function obj = MLCompileCommsTest(config, hostID, hostOS,...
                         hostScratchDir, targetBaseDir,...
                         auth, log, ~)
            obj = obj@MachineCommsTest(config, hostID, hostOS,...
                              hostScratchDir, targetBaseDir, auth, log);
            obj.configureDualKey(config);
        end
    end
end