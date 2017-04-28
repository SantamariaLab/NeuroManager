classdef Cmp03 < Comparator
    properties
        name;
    end
    methods
        function obj = Cmp03(expDBConn, simDB)
            obj = obj@Comparator(expDBConn, simDB);
        end
        
        % This comparator type compares only one specimen/exp with each
        % simulation in the simulation list.
        % simulation.
        % Features compared: 
        %       hasSpikes T/F, mean_isi (score1)
        %       hasSpikes T/F, latency, mean_isi (score2)
        %       hasSpikes T/F, latency, mean_isi, adaptation  (score3)
        % Measure: L2 norm
        function results = compare(obj, specIDList, expIDList, ...
                                        simList, addToDatabase)
            specID = specIDList{1};
            expID = expIDList{1};
            obj.name = 'CMP03';   % TEMPORARY APPROACH
            
            %% Get the experimental features for comparison
            q = ['SELECT experimentFXs.hasSpikes, ' ...
                 'experimentFXs.latency, experimentFXs.ISIMean, ' ...
                 'experimentFXs.numSpikes, experimentFXs.adaptation ' ...
                 'FROM ((experimentFXs INNER JOIN experiments ' ...
                 'ON experimentFXs.expFXIDX=experiments.expFXIDX) ' ...
                 'INNER JOIN specimens ' ...
                 'ON experiments.specIDX=specimens.specIDX) ' ...
                 'WHERE specimens.abiSpecimenID=' specID ...
                 ' AND experiments.abiExpID=' expID ';'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.expDBConn, q);
            curs = fetch(curs);
            temp = curs.Data
            expHasSpikes = temp.hasSpikes;
            expMeanISI = temp.ISIMean;
            expStimulusLatency = temp.latency;
            expAdaptation = temp.adaptation;
            
            %% Do the comparison for each simulation in the list
            for i=1:size(simList,1)
                %% Get the simulation features
                q = [ ...
                 'SELECT simFeatureExtractions.hasSpikes, ' ...
                 'simFeatureExtractions.stimulusLatency, ' ...
                 'simFeatureExtractions.mean_isi, ' ...
                 'simFeatureExtractions.adaptation, ' ...
                 'simulationRuns.runIDX ' ...
                 'FROM ((simFeatureExtractions INNER JOIN simulationRuns ' ...
                 'ON simFeatureExtractions.fxIDX=simulationRuns.fxIDX) ' ...
                 'INNER JOIN sessions ' ...
                 'ON simulationRuns.sessionIDX=sessions.sessionIDX) ' ...
                 'WHERE sessions.dateTime=' '"' simList{i,1}.sessionID '"' ...
                 ' AND simulationRuns.simID=' '"' simList{i,1}.simID '" ' ...
                 ' AND simulationRuns.simSetID=' '"' simList{i,1}.simSetID '" ' ...
                 ';'];
                setdbprefs('DataReturnFormat','structure');
                curs = exec(obj.simDB.getConn(), q);
                curs = fetch(curs);
                temp = curs.Data;

                simHasSpikes = temp.hasSpikes;
                % have to convert to seconds for the comparison
                simStimulusLatency = temp.stimulusLatency/1000.0;
                % have to convert to seconds for the comparison
                simMeanISI = temp.mean_isi/1000.0;
                simAdaptation = temp.adaptation;
                runIndex = temp.runIDX;

                %% Perform the subclass-specific comparisons
%                 results{i} = struct; %#ok<*AGROW>
                results{i} = simList{i,1}; %#ok<*AGROW>
                % This comparator requires spikes in both
                if ~(expHasSpikes && simHasSpikes)
                    results{i}.score1 = realmax('double');
                    results{i}.score2 = realmax('double');
                    results{i}.score3 = realmax('double');
                else
                    results{i}.score1 = ...
                             abs((simMeanISI - expMeanISI) ...
                                / expMeanISI ...
                                 );
                    results{i}.score2 = ...
                        sqrt( ...
                             ((simStimulusLatency - expStimulusLatency) ...
                                / expStimulusLatency ...
                              )^2 * 0.5 + ...
                             ((simMeanISI - expMeanISI) ...
                                / expMeanISI ...
                              )^2 * 0.5 ...
                             );

                    results{i}.score3 = ...
                        sqrt( ...
                             ((simStimulusLatency - expStimulusLatency) ...
                                / expStimulusLatency ...
                              )^2 / 3.0 + ...
                             ((simAdaptation - expAdaptation) ...
                                / expAdaptation * 1.0 ...
                              )^2 / 3.0 + ...
                             ((simMeanISI - expMeanISI) ...
                                / expMeanISI * 1.0 ...
                              )^2 / 3.0 ...
                             );

                end
                results{i}.score4 = NaN;
                results{i}.score5 = NaN;
                disp(['runIDX=' num2str(runIndex) ...
                      ', simID=' simList{i}.simID ': ' ...
                      ', simStimulusLatency = ' num2str(simStimulusLatency) ...
                      ', expStimulusLatency = ' num2str(expStimulusLatency) ...
                      ', simMeanISI = ' num2str(simMeanISI) ...
                      ', expMeanISI = ' num2str(expMeanISI) ...
                      ', simAdaptation = ' num2str(simAdaptation) ...
                      ', expAdaptation = ' num2str(expAdaptation) ...
                      ', score1 = ' num2str(results{i}.score1) ...
                      ', score2 = ' num2str(results{i}.score2) ...
                      ', score3 = ' num2str(results{i}.score3) ...
                      ]);

                %% Add the results to the investigation database  
                if addToDatabase
                    results{i}.compIndex = ...
                        obj.simDB.addComparison(runIndex, obj.name, ...
                                results{i}.score1, results{i}.score2, ...
                                results{i}.score3, results{i}.score4, ...
                                results{i}.score5);
                end
            end            
        end
    end
end
