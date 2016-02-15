classdef Server < RunJobMachine
    properties
    end
    methods
        function obj = Server(md, xCmpMach, xCmpDir,...
                                    hostID, hostOS, ~, auth)
            obj = obj@RunJobMachine(md, xCmpMach, xCmpDir,...
                                     hostID, hostOS, auth);
            obj.configureDualKey(md);
        end
    end
end