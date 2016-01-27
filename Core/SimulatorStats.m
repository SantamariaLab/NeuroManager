% SimulatorStats.m
% Deals with a Simulator's timing statistics for the Scheduler's use.
% Times assumed to be in seconds

classdef SimulatorStats < handle
    properties
        prepTimes;
        waitTimes;
        runTimes;
        finishTimes;
        updateStats;
        numSims;
        meanPrepTime;
        stdDevPrepTime;
        meanWaitTime;
        stdDevWaitTime;
        meanRunTime;
        stdDevRunTime;
        meanFinishTime;
        stdDevFinishTime;
    end
    
    methods
        function obj = SimulatorStats()
            obj.prepTimes = [];
            obj.waitTimes = [];
            obj.runTimes = [];
            obj.finishTimes = [];
            obj.updateStats = true;
            obj.numSims = 0;
            obj.meanPrepTime = inf;
            obj.stdDevPrepTime = 0.0;
            obj.meanWaitTime = inf;
            obj.stdDevWaitTime = 0.0;
            obj.meanRunTime = inf;
            obj.stdDevRunTime = 0.0;
            obj.meanFinishTime = inf;
            obj.stdDevFinishTime = 0.0;
        end
        
        function addData(obj, TP, TW, TR, TF)
            obj.numSims = obj.numSims + 1;
            obj.prepTimes(obj.numSims) = TP;
            obj.waitTimes(obj.numSims) = TW;
            obj.runTimes(obj.numSims) = TR;
            obj.finishTimes(obj.numSims) = TF;
            if obj.updateStats
                obj.meanPrepTime = mean(obj.prepTimes);
                obj.stdDevPrepTime = std(obj.prepTimes);
                obj.meanWaitTime = mean(obj.waitTimes);
                obj.stdDevWaitTime = std(obj.waitTimes);
                obj.meanRunTime = mean(obj.runTimes);
                obj.stdDevRunTime = std(obj.runTimes);
                obj.meanFinishTime = mean(obj.finishTimes);
                obj.stdDevFinishTime = std(obj.finishTimes);
            end
        end
        
        function setStats(obj, mPT, sPT, mWT, sWT, mRT, sRT, mFT, sFT)
                obj.meanPrepTime = mPT;
                obj.stdDevPrepTime = sPT;
                obj.meanWaitTime = mWT;
                obj.stdDevWaitTime = sWT;
                obj.meanRunTime = mRT;
                obj.stdDevRunTime = sRT;
                obj.meanFinishTime = mFT;
                obj.stdDevFinishTime = sFT;
        end
        
        function [mPT, sPT, mWT, sWT, mRT, sRT, mFT, sFT] = getStats(obj)
                mPT = obj.meanPrepTime;
                sPT = obj.stdDevPrepTime;
                mWT = obj.meanWaitTime;
                sWT = obj.stdDevWaitTime;
                mRT = obj.meanRunTime;
                sRT = obj.stdDevRunTime;
                mFT = obj.meanFinishTime;
                sFT = obj.stdDevFinishTime;
        end
        
        function setUpdateStats(obj)
            obj.updateStats = true;
        end
        
        function clearUpdateStats(obj)
            obj.updateStats = false;
        end
    end
end
