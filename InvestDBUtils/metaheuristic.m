% metaheuristic
% A class for NM parameter space investigation
% NOT COMPLETE
classdef metaheuristic < handle
    properties
        initData;
        terminate;
        name = '';
    end
    methods (Abstract)
        getPointSet(obj)
    end
    
    methods
        function obj = metaheuristic(initData, name)
            obj.initData = initData;
            obj.terminate = false;
            obj.name = name;
        end
        
        function name = getName(obj)
            name = obj.name;
        end
    end
    
end