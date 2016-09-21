classdef Server < RunJobMachine
    properties
    end
    methods
        function obj = Server(config, hostID, hostOS, auth)
            obj = obj@RunJobMachine(config, hostID, hostOS, auth);
            obj.configureDualKey(config);
        end
    end
end