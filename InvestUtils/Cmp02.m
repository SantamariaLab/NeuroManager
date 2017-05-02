classdef Cmp02 < Comparator
    properties
    end
    methods
        function obj = Cmp02(expDBConn, simDB, expDataDir, cURLBinDir)
            obj = obj@Comparator(expDBConn, simDB, expDataDir, cURLBinDir);
            obj.numScoresUsed = 1;
            obj.name = 'CMP02';
        end
        
        % This comparator type compares only one specimen/exp with each
        % simulation in the simulation list.
        % simulation.
        % Features compared: hasSpikes T/F, latency and mean_isi equally
        % Measure: L2 norm
        function results = compare(obj, specIDList, expIDList, simList)
            specID = specIDList{1};
            expID = expIDList{1};
            
            %% Get the experimental features for comparison
            expFX = obj.getExpExpFXData(specID, expID);
            expHasSpikes = expFX.hasSpikes;
            expNumSpikes = expFX.numSpikes;
            expMeanISI = expFX.ISIMean;
            expStimulusLatency = expFX.latency;
            expAdaptation = expFX.adaptation;
            
            %% Do the comparison for each simulation in the list
            for i=1:size(simList,1)
                %% Get the simulation features
                simFX = obj.simDB.getSimFeatureExtraction(...
                                    simList{i}.sessionID, ...
                                    simList{i}.simSetID, simList{i}.simID);
                if ~isstruct(simFX)
                    results = {};
                    return;
                end
                simHasSpikes = simFX.hasSpikes;
                simStimulusLatency = simFX.stimulusLatency;
                simISIMean = simFX.mean_isi;
                simNumSpikes = simFX.numSpikes;
                simAdaptation = simFX.adaptation;
                runIndex = simFX.runIDX;

                %% Perform the subclass-specific comparison
                results{i} = simList{i}; %#ok<*AGROW>
                if xor(expHasSpikes, simHasSpikes)
                    results{i}.score1 = realmax('double');
                else
                    results{i}.score1 = ...
                        sqrt( ...
                             ((simStimulusLatency - expStimulusLatency) ...
                                / expStimulusLatency * 1.0 ...
                              )^2 + ...
                             ((simAdaptation - expAdaptation) ...
                                / expAdaptation * 1.0 ...
                              )^2 + ...
                             ((simISIMean - expMeanISI) ...
                                / expMeanISI * 1.0 ...
                              )^2 + ...
                             ((simNumSpikes - expNumSpikes) ...
                                / expNumSpikes * 1.0 ...
                              )^2 ...
                             );
                end
                results{i}.score2 = NaN;
                results{i}.score3 = NaN;
                results{i}.score4 = NaN;
                results{i}.score5 = NaN;
                disp(['simID=' simList{i}.simID ': ' ...
                    'simHasSpikes = ' num2str(simHasSpikes) ...
                      ', simStimulusLatency = ' num2str(simStimulusLatency) ...
                      ', simMeanISI = ' num2str(simISIMean) ...
                      ', score1 = ' num2str(results{i}.score1)]);

                %% Add the results to the investigation database  
                compIndex = obj.simDB.addComparison(runIndex, obj.name, ...
                                results{i}.score1, results{i}.score2, ...
                                results{i}.score3, results{i}.score4, ...
                                results{i}.score5);
            end            
        end
    end
end
