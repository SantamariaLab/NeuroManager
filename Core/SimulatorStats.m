% SimulatorStats.m
% Deals with a Simulator's timing statistics for the Scheduler's use.

classdef SimulatorStats < handle
    properties
        waitTimes;
        runTimes;
        updateStats;
        numSims;
        meanWaitTime;
        stdDevWaitTime;
        meanRunTime;
        stdDevRunTime;
    end
    
    methods
        function obj = SimulatorStats()
            obj.waitTimes = [];
            obj.runTimes = [];
            obj.updateStats = true;
            obj.numSims = 0;
            obj.meanWaitTime = 0.0;
            obj.stdDevWaitTime = 0.0;
            obj.meanRunTime = 0.0;
            obj.stdDevRunTime = 0.0;
        end
        
        function addData(obj, TW, TR)
            obj.numSims = obj.numSims + 1;
            obj.waitTimes(obj.numSims) = TW;
            obj.runTimes(obj.numSims) = TR;
            if obj.updateStats
                obj.meanWaitTime = mean(obj.waitTimes);
                obj.stdDevWaitTime = std(obj.waitTimes);
                obj.meanRunTime = mean(obj.runTimes);
                obj.stdDevRunTime = std(obj.runTimes);
            end
        end
        
        function setStats(obj, mWT, sWT, mRT, sRT)
                obj.meanWaitTime = mWT;
                obj.stdDevWaitTime = sWT;
                obj.meanRunTime = mRT;
                obj.stdDevRunTime = sRT;
        end
        
        function [mWT, sWT, mRT, sRT] = getStats(obj)
                mWT = obj.meanWaitTime;
                sWT = obj.stdDevWaitTime;
                mRT = obj.meanRunTime;
                sRT = obj.stdDevRunTime;
        end
        
        function setUpdateStats(obj)
            obj.updateStats = true;
        end
        
        function clearUpdateStats(obj)
            obj.updateStats = false;
        end
    end
end
