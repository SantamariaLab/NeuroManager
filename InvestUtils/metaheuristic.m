% metaheuristic
% A class for NM parameter space investigation
classdef metaheuristic < handle
    properties
        initData;
        terminate;  % t/f
        name = '';
        % generation number refers to the generation in play; i.e., the
        % set of points delivered by the previous getPointSet().  The first
        % generation is the zeroth generation. 
        generationNumber;  
    end
    methods (Abstract)
        getPointSet(obj)
    end
    
    methods
        function obj = metaheuristic(initData, name)
            obj.initData = initData;
            obj.terminate = false;
            obj.name = name;
            obj.generationNumber = -1;
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function gen = getGenerationNumber(obj)
            gen = obj.generationNumber;
        end
        
        function resetGenerationNumber(obj)
            obj.generationNumber = -1;
        end
    end
    
    methods (Access=protected)
        function incrementGenerationNumber(obj)
            obj.generationNumber = obj.generationNumber + 1;
        end
    end
end