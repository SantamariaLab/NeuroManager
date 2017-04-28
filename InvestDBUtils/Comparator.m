% Comparator.m
% Base class for exp-simulation comparisons.
classdef Comparator < handle
    properties
        cmpFunc;
        expDBConn;
        simDB;
    end
    properties (Abstract)
        name;
    end
    
    methods (Abstract)
        compare(obj)
%         visualize(obj)
    end
    
    methods
        function obj = Comparator(expDBConn, simDB)
            obj.expDBConn = expDBConn;
            obj.simDB = simDB;
        end
        
        function name = getName(obj)
            name = obj.name;
        end
    end
end