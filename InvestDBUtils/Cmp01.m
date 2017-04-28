classdef Cmp01 < Comparator
    properties
    end
    methods
        function obj = Cmp01(expDBConn, simDB)
            obj = obj@Comparator(expDBConn, simDB);
        end
        
        % This comparator type compares only one specimen/exp with each
        % simulation in the simulation list.
        % simulation.
        % Features compared: hasSpikes T/F, latency, mean_isi
        % Measure: L2 norm
        function results = compare(obj, specIDList, expIDList, simList)
            specID = specIDList{1};
            expID = expIDList{1};
            cmpType = 'CMP01';   % TEMPORARY
            
            %% Get the experimental features for comparison
            q = ['SELECT experimentFXs.hasSpikes, ' ...
                 'experimentFXs.latency, experimentFXs.mean_isi ' ...
                 'FROM ((experimentFXs INNER JOIN experiments ' ...
                 'ON experimentFXs.id=experiments.expFXID) ' ...
                 'INNER JOIN specimens ' ...
                 'ON experiments.specimenIDX=specimens.id) ' ...
                 'WHERE specimens.abiSpecimenID=' specID ...
                 ' AND experiments.abiExperimentID=' expID ';'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.expDBConn, q);
            curs = fetch(curs);
            temp = curs.Data;
            expHasSpikes = temp.hasSpikes;
            expStimulusLatency = temp.latency;
            expMeanISI = temp.mean_isi;
            
            %% Do the comparison for each simulation in the list
            for i=1:size(simList,2)
                %% Get the simulation features
                q = ['SELECT simFeatureExtractions.hasSpikes, ' ...
                     'simFeatureExtractions.latency, ' ...
                     'simFeatureExtractions.mean_isi, ' ...
                     'simulationRuns.runIDX ' ...
                     'FROM ((simFeatureExtractions INNER JOIN simulationRuns ' ...
                     'ON simFeatureExtractions.fxIDX=simulationRuns.runIDX) ' ...
                     'INNER JOIN sessions ' ...
                     'ON simulationRuns.sessionIDX=sessions.sessionIDX) ' ...
                     'WHERE sessions.dateTime=' '"' ...
                        simList{i}.sessionID '"' ...
                     ' AND simulationRuns.simID=' '"' ...
                        simList{i}.simID '" ' ...
                     ' AND simulationRuns.simSetID=' '"' ...
                        simList{i}.simSetID '" ' ...
                     ';'];
                setdbprefs('DataReturnFormat','structure');
                curs = exec(obj.simDB.getConn(), q);
                curs = fetch(curs);
                temp = curs.Data;

                simHasSpikes = temp.hasSpikes;
                simStimulusLatency = temp.latency;
        %         simStimulusLatency = temp.stimulusLatency;
                simMeanISI = temp.mean_isi;
                runIndex = temp.runIDX;

                %% Perform the subclass-specific comparison
%                 results{i} = struct; %#ok<*AGROW>
                results{i} = simList{i}; %#ok<*AGROW>
                if xor(expHasSpikes, simHasSpikes)
                    results{i}.score1 = realmax('double');
                else
                    results{i}.score1 = ...
                        sqrt((simStimulusLatency - expStimulusLatency)^2 + ...
                             (expMeanISI - simMeanISI)^2);
                end
                results{i}.score2 = NaN;
                results{i}.score3 = NaN;
                results{i}.score4 = NaN;
                results{i}.score5 = NaN;
                disp(['simID=' simList{i}.simID ': ' ...
                      'simHasSpikes = ' num2str(simHasSpikes) ...
                      ', simStimulusLatency = ' num2str(simStimulusLatency) ...
                      ', simMeanISI = ' num2str(simMeanISI) ...
                      ', score1 = ' num2str(results{i}.score1)]);

                %% Add the results to the investigation database  
                compIndex = obj.simDB.addComparison(runIndex, cmpType, ...
                                results{i}.score1, results{i}.score2, ...
                                results{i}.score3, results{i}.score4, ...
                                results{i}.score5);
            
%                 %% Massage the results for database insertion
%                 if isnan(results{i}.score1)
%                     score1Str = 'NULL';
%                 else
%                     % precision is important to get by MySQL input
%                     score1Str = num2str(results{i}.score1, 14);
%                 end 
%                 if isnan(results{i}.score2)
%                     score2Str = 'NULL';
%                 else
%                     score2Str = num2str(results{i}.score2);
%                 end 
%                 if isnan(results{i}.score3)
%                     score3Str = 'NULL';
%                 else
%                     score3Str = num2str(results{i}.score3);
%                 end 
%                 if isnan(results{i}.score4)
%                     score4Str = 'NULL';
%                 else
%                     score4Str = num2str(results{i}.score4);
%                 end 
%                 if isnan(results{i}.score5)
%                     score5Str = 'NULL';
%                 else
%                     score5Str = num2str(results{i}.score5);
%                 end 
                
%                 if isinf(results{i}.score1)
%                     score1Str = 'Double.MAX_VALUE';
%                 end
                % ADD MORE OF THOSE 
                % (not implemented yet)

                %% Add the comparison to the database
%                 colnames = {'cmpIDX', 'runIDX', 'cmpType', ...
%                             'score1', 'score2', 'score3', ...
%                             'score4', 'score5'};
%                 coldata = {num2str(runIDX), ...
%                            ['''' cmpType ''''], ...
%                            score1Str, score2Str, score3Str, score4Str, score5Str};
%                 insertStr = ['insert into comparisons (' ...
%                              strjoin(colnames, ', ') ') values(0, ' ...
%                              strjoin(coldata, ', ') ')']
%                 try % temp for debug
%                     curs = exec(obj.simDBConn, insertStr)
%                     close(curs)
%                 catch ME
%                     disp(['Error inserting comparison:' ME.identifier])
%                 end
            end            
        end
        
        function visualize(obj)
        end
    end
end