% SimulatorData.m
% A class for mustering the available simulator data for use by a NeuroManager
% Virtual Scheduler.

classdef SimulatorData < handle
    properties
        numSimulators = 0;
        simulatorData = struct([]);
    end
    
    methods
%         function obj = SimulatorData()
%         end
        
        % -----
        function addSimulatorData(obj, simulator)
            obj.numSimulators = obj.numSimulators + 1;
            obj.simulatorData(obj.numSimulators).state = simulator.getState();
            if obj.simulatorData(obj.numSimulators).state == SimulatorState.BUSY
                [handoffTime, submissionTime, runStartTime,...
                 runCompleteTime, simFullProcTime] =...
                                        simulator.currentSimulation.getStats();
                obj.simulatorData(obj.numSimulators).handoffTime =...
                                                            handoffTime;
                obj.simulatorData(obj.numSimulators).submissionTime =...
                                                            submissionTime;
                obj.simulatorData(obj.numSimulators).runStartTime =...
                                                            runStartTime;
                obj.simulatorData(obj.numSimulators).runCompleteTime =...
                                                            runCompleteTime;
                obj.simulatorData(obj.numSimulators).simFullProcTime =...
                                                            simFullProcTime;
                obj.simulatorData(obj.numSimulators).simulationState = ...
                                        simulator.currentSimulation.getState();
                obj.simulatorData(obj.numSimulators).ETS = ...
                                        simulator.currentSimulation.getETS();
            else
                obj.simulatorData(obj.numSimulators).handoffTime     = datetime('');
                obj.simulatorData(obj.numSimulators).submissionTime  = datetime('');
                obj.simulatorData(obj.numSimulators).runStartTime    = datetime('');
                obj.simulatorData(obj.numSimulators).runCompleteTime = datetime('');
                obj.simulatorData(obj.numSimulators).simFullProcTime = datetime('');
                obj.simulatorData(obj.numSimulators).simulationState = ...
                                        simulator.currentSimulation.getState();
                obj.simulatorData(obj.numSimulators).ETS = 0.0;
            end
            % This is probably very politically incorrect:
            obj.simulatorData(obj.numSimulators).stats = simulator.stats;
            obj.simulatorData(obj.numSimulators).currentTime =...
                                                simulator.getCurrentTime();
        end
        
        % -----
        function simData = getSimulatorData(obj, index)
            simData = struct();
            simData.state = obj.simulatorData(index).state;
            simData.handoffTime     = obj.simulatorData(index).handoffTime;
            simData.submissionTime  = obj.simulatorData(index).submissionTime;
            simData.runStartTime    = obj.simulatorData(index).runStartTime;
            simData.runCompleteTime = obj.simulatorData(index).runCompleteTime;
            simData.simFullProcTime = obj.simulatorData(index).simFullProcTime;
            simData.simulationState = obj.simulatorData(index).simulationState;
            simData.ETS = obj.simulatorData(index).ETS;
            simData.stats = obj.simulatorData(index).stats;
            simData.currentTime = obj.simulatorData(index).currentTime;
        end
       
        % ----- a repeat of the NeuroManager one... perhaps that one is no
        % longer required?
        function tf = isSimulatorAvailable(obj)
            tf = false;
            for i=1:obj.numSimulators
                if obj.simulatorData(i).state == SimulatorState.AVAILABLE
                    tf = true;
                    break;
                end
            end
        end
        
        function tf = isSimulatorBusy(obj)
            tf = false;
            for i=1:obj.numSimulators
                if obj.simulatorData(i).state == SimulatorState.BUSY
                    tf = true;
                    break;
                end
            end
        end

        function num = getNumSimulators(obj)
            num = obj.numSimulators;
        end
    end
end
