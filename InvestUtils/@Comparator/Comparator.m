% Comparator.m
% Base class for exp-simulation comparisons.
classdef Comparator < handle
    properties
        expDBConn;
        expFXData;
        simDB;
        expDataDir;     % For vis only; remove in future
        cURLBinDir;     % For vis only; remove in future
        numScoresUsed;  % For now, <= 5
        name = 'NEEDS NAME (=TYPE)';
    end
    
    methods (Abstract)
        compare(obj)
    end

    methods
        function obj = Comparator(expDBConn, simDB, expDataDir, cURLBinDir)
            obj.expDBConn = expDBConn;
            obj.expFXData = ABIFeatExtrData(obj.expDBConn);
            obj.simDB = simDB;
            obj.expDataDir = expDataDir;
            obj.cURLBinDir = cURLBinDir;
            obj.numScoresUsed = 0;
        end
        
        function num = getNumScoresUsed(obj)
            num = obj.numScoresUsed;
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function data = getExpExpFXData(obj, specNum, expNum)
            data = obj.expFXData.getExpFXData(specNum, expNum);
        end

        function data = getExpSpecFXData(obj, specNum)
            data = obj.expFXData.getSpecFXData(obj, specNum);
        end
        
        function info = getExpExpInfo(obj, specNum, expNum)
            info = obj.expFXData.getExpInfo(obj, specNum, expNum);
        end
        
        visComparison(obj, cmpIDX, highlightSpikeInsertion)
    end
end
