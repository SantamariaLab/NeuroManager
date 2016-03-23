classdef Server < RunJobMachine
    properties
    end
    methods
        function obj = Server(config, xCmpMach, xCmpDir,...
                                    hostID, hostOS, ~, auth)
            obj = obj@RunJobMachine(config, xCmpMach, xCmpDir,...
                                     hostID, hostOS, auth);
            obj.configureDualKey(config);
        end
    end
end