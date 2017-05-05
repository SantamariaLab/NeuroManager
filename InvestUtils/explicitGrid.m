% explicitGrid
% explores every combination of input parameters
% limit 5 dimensions
% all cell arrays for handling both numbers and strings in input
classdef explicitGrid < metaheuristic
    properties
    end
    methods
        function obj = explicitGrid(initData)
            if length(initData) > 5
                error('explicitGrid parameter space limited to 5 dimensions');
            end
            if length(initData) < 1
                error('explicitGrid parameter space must have at least 1 dimension');
            end
            if min(size(initData)) < 1
                error('Each explicitGrid parameter must have at least 1 entry');
            end
            obj = obj@metaheuristic(initData, 'explicitGrid');
        end
        
        % For now, get all the points at once.
        function points = getPointSet(obj)
            obj.incrementGenerationNumber();
            if obj.terminate
                points = [];
                return;
            end
            numParams = length(obj.initData);
            numPoints = 1;
            for i = 1:numParams
                numPoints = numPoints * length(obj.initData{i});
            end
            accDiv = 1;
            for i = 1:numParams
                accDiv = accDiv * numel(obj.initData{i});
                cycleDiv(i) = numPoints/accDiv; %#ok<AGROW>
            end
            points = cell(numPoints, numParams);
            % Fill in the points
            for ptNum = 1:numPoints
                for i = 1:numParams
                    points{ptNum, i} = ...
                        obj.initData{i}{mod(floor((ptNum-1)/cycleDiv(i)), ...
                                            numel(obj.initData{i})) + 1};
                end
            end
            obj.terminate = true;
        end

    end
end
