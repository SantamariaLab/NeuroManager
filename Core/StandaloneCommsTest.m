classdef StandaloneCommsTest < MachineCommsTest
    methods
        function obj = StandaloneCommsTest(config, hostID, hostOS,...
                         hostScratchDir, targetBaseDir, auth, log, ~)
            obj = obj@MachineCommsTest(config, hostID, hostOS,...
                         hostScratchDir, targetBaseDir, auth, log);
	% WHY NO CONFIGURE KEY HERE?
        end
    end
end