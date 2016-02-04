% Scheduler2p0.m
% Implements the Scheduler2.0 algorithm.

function actionsList = Scheduler2p0(simulatorData,...
                                    availableSimulations,...
                                    avgCyclePeriod)
    actionsList = [];
    numSimulators = simulatorData.getNumSimulators();
	
    
    % Submission
%         if (obj.nmSimSet.hasUNRUN())
    if availableSimulations ~= 0

        % Are Open Simulators available? If so, we do a schedule;
        % otherwise we do nothing
        if simulatorData.isSimulatorAvailable()
            % Create new min-min schedule
              % row 1: simulator index
              % row 2: simulator ETA in datetime format
              % row 3: simulator-specific ETS for a simulation started now
              % row 4: Additional loop correction time for busy simulators
              % row 5: ETC = ETA + ETS + loop correction 
              % row 6: Simulator availability (AVAILABLE = 1, BUSY = 0
              % for ability to secondary sort; RETIRED = -1) 
            schedule = zeros(6, numSimulators);
            schedule(1, :) = [1:numSimulators];
            for i = 1:numSimulators
                thisSimulatorData = simulatorData.getSimulatorData(i);
                currentTime = thisSimulatorData.currentTime;
                if thisSimulatorData.state == SimulatorState.AVAILABLE
                    schedule(2, i) = 0.0;
                    [mPT, ~, mWT, ~, mRT, ~, mFT, ~] = ...
                                        thisSimulatorData.stats.getStats();
                    schedule(3, i) = mPT + mWT + mRT + mFT;
                    schedule(4, i) = 0.0;
                    schedule(6, i) = 1;
                elseif thisSimulatorData.state == SimulatorState.BUSY
                    handoffTime = thisSimulatorData.handoffTime;
                    ETS = thisSimulatorData.ETS;
                    schedule(2, i) = ...
                            ETS + seconds(handoffTime - currentTime);
                    % If it ended in the past for whatever reason (such
                    % as an initial ETS=0), bring the ETA to now
                    if schedule(2,i) < 0
                        schedule(2,i) = 0;
                    end
                    [mPT, ~, mWT, ~, mRT, ~, mFT, ~] = ...
                                        thisSimulatorData.stats.getStats();
                    schedule(3, i) = mPT + mWT + mRT + mFT;
                    schedule(4, i) = avgCyclePeriod;
                    schedule(6, i) = 0;
                else
                    % Simulator is RETIRED and needs to stay out of the
                    % way of the scheduler; -1 will sort to the right
                        schedule(2, i) = 0.0;
                        schedule(3, i) = inf;
                        schedule(4, i) = 0.0;
                        schedule(6, i) = -1;
                end 
                schedule(5, i) = sum(schedule(2:4, i));

                % Untried simulators have infinite stats to
                % ensure proper sorting but we don't want that to
                % keep them from being passed over in favor of a
                % simulator already in use, so we ensure they will 
                % be at the head of the line.
                if (isinf(schedule(2,i)) && (schedule(6,i) == 1))
                    schedule(5,i) = -1;
                end
            end

            % Running simulators can end up here with a 0 ETS due to
            % startup situations, which blocks further placements until 
            % they have finished running; to avoid that we just want to
            % move them back in the queue temporarily. So for the sort
            % we replace their ETC with the max ETC of all
            % simulators; it will be replaced like this until the
            % simulation finishes and real data comes into the ETS.
            maxETC = max(schedule(5,:));
            for i = 1:numSimulators
                if (schedule(3,i)==0 && schedule(6,i) == 0)
                    schedule(5,i) = maxETC;
                end
            end

            % Sorting the columns by the ETC puts the simulator indices
            % in order of likely-to-finish-first; within ties the
            % available simulators come first.
            sortedSchedule = sortrows(schedule', [5 -6])';
            if 1  % just for monitor/debug
                fprintf('\n -----\nAverage Cycle Period: %f\n', avgCyclePeriod);
                for i = 1:6
                    fprintf([repmat('% 5.0f ', 1, numSimulators) '\n'],...
                        sortedSchedule(i,:));
                end
            end

            % -------------
            % Place Scheduled Simulations on Assigned Simulators if
            % Open, until hit an unavailable simulator
            % (Create actions for action list to do so, that is)
            simulationsScheduled = 0;
            for i = 1:numSimulators
                % Stop scheduling when hit an unavailable Simulator
                if sortedSchedule(6, i) == 0
                    break;
                end
                
                % Get the simulation (if there is one left) started on
                % the simulator
                if simulationsScheduled <= availableSimulations
                    simulatorIndex = sortedSchedule(1, i);
                    actionsList= ...
                        vertcat(actionsList,...
                            [SchedulerActions.PLACESIMULATION ...
                             simulatorIndex 0]);
                    simulationsScheduled = simulationsScheduled + 1;
                else
                    % if no Unrun simulations left then get out of this loop
                    break;
                end
            end
        else
            % No simulators available so wait for one
            actionsList = vertcat(actionsList, [SchedulerActions.NTD 0 0]);
        end
            
    else 
        % All Simulations Finished?
%             if (obj.nmSimSet.isFullyProcessed())
        if ((availableSimulations == 0) && ...
            (~simulatorData.isSimulatorBusy()))
            actionsList = vertcat(actionsList, [SchedulerActions.FINISHED 0 0]);
        else
            % Here all Simulations are in play, but we need to see if
            % any Simulation in SUBMITTED state is stuck in a 
            % waiting queue by seeing if its current TW is greater than
            % the average time to do a complete simulation for all
            % Simulators; if so, retire that Simulator 
            % and put the Simulation back on the Unrun list to be
            % rescheduled. 
            %
            % Gather average time to do a complete simulation
            for i  = 1:numSimulators
                thisSimulatorData = simulatorData.getSimulatorData(i);
                [mPT, ~, mWT, ~, mRT, ~, mFT, ~] = ...
                                    thisSimulatorData.stats.getStats();
                currentAvgTS(i)= mPT + mWT + mRT + mFT;  
            end
            averageSimulationDuration = mean(currentAvgTS(:));

            % Now search and reschedule if necessary
            % Avoid any rescheduling in first cycle
            if averageSimulationDuration > 0.0
                % Reschedule all simulations that qualify
                for i  = 1:numSimulators
                    thisSimulatorData = simulatorData.getSimulatorData(i);
                    % Only busy simulators
                    if thisSimulatorData.state == SimulatorState.BUSY
                        % Only simulations in the SUBMITTED state
                        if thisSimulatorData.simulationState == SimulationState.SUBMITTED
                            timeSubmitted = thisSimulatorData.submissionTime();
                            currentTime = thisSimulatorData.currentTime();
                            timeInWaitQueue = seconds(currentTime - timeSubmitted);
                            % Only simulations waiting longer than
                            % a full simulation on a different simulator
                            if timeInWaitQueue > averageSimulationDuration
                                % Take the simulation away from the
                                %   Simulator and deactivate the Simulator
                                actionsList = vertcat(actionsList,...
                                    [SchedulerActions.CANCELRETURN i 0]); %#ok<*AGROW>
                                actionsList = vertcat(actionsList,...
                                    [SchedulerActions.RETIRESIMULATOR i 0]);
                            end
                        end 
                    end 
                end  
            end 
        end
    end
end
