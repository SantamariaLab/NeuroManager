classdef Server < RunJobMachine
    properties
%         config;
    end
    methods
        function obj = Server(config, xCmpMach, xCmpDir,...
                                    hostID, hostOS, ~, auth)
            obj = obj@RunJobMachine(config, xCmpMach, xCmpDir,...
                                     hostID, hostOS, auth);
            obj.configureDualKey(config);
%             obj.config = config;
        end
    end
end