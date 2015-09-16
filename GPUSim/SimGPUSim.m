% SimGPUSim
% The simulator class that defines the GPUSim Simulator
classdef SimGPUSim < SimNoModelMLOnly
    properties
        version;
    end
    
    methods
        function obj = SimGPUSim(simulatorID,...
                                machine,...
                                log, notificationSet)
            addlStdFileList = {};
            addlCustFileList = {'collectGPUData.m'};
            obj = obj@SimNoModelMLOnly(simulatorID,...
                                       addlStdFileList,...
                                       addlCustFileList,...
                                       machine,...
                                       log, notificationSet);
            obj.version = '1.0';  % Will be recorded in log
        end
    end 
end
