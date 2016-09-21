% SimGPUSim
% The simulator class that defines the GPUSim Simulator
classdef SimGPUSim < SimNoModelMLOnly
    properties
        version;
    end
    properties (Access=private)
        addlCustomFileList = {};
    end
    
    methods
        function obj = SimGPUSim(simulatorID, machine,...
                                log, notificationSet)
            obj = obj@SimNoModelMLOnly(simulatorID, machine,...
                                       log, notificationSet);
%             obj.addlCustomFileList = {'collectGPUData.m'};
            obj.version = '1.0';  % Will be recorded in log
        end
        
        % ---
        function list = getAddlCustomFileList(obj)
            list = getAddlCustomFileList@Simulator(obj);
            list = [list obj.addlCustomFileList];
        end

    end 
end
