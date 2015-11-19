classdef SimType
    properties
        constrFunc;
    end
    methods
        function t = SimType(func)
            t.constrFunc = func;
        end
    end
    enumeration
        % Type name                         (@ConstructorName)
        
        % Mostly for constructor-ish stuff; must be present!
        UNASSIGNED                          (0)
            
        % A MATLAB-only GPU simulator that plots sine waves and does an FFT
        SIM_GPUSIM                          (@SimGPUSim)
    end
end