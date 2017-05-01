classdef Cmp01 < Comparator
    properties
    end
    methods
        function obj = Cmp01(expDBConn, simDB)
            obj = obj@Comparator(expDBConn, simDB);
            obj.numScoresUsed = 1;
            obj.name = 'CMP01';
        end
        
        % This comparator type compares only one specimen/exp with each
        % simulation in the simulation list.
        % Features compared: hasSpikes T/F, latency, mean_isi
        % Measure: L2 norm
        function results = compare(obj, specIDList, expIDList, simList)
            specID = specIDList{1}
            expID = expIDList{1}
            
            %% Get the experimental features for comparison
            expFX = obj.getExpExpFXData(specID, expID);
            expHasSpikes = expFX.hasSpikes;
            expStimulusLatency = expFX.latency;
            expISIMean = expFX.ISIMean;
            
            %% Do the comparison for each simulation in the list
            for i=1:size(simList,1)
                %% Get the simulation features
                simFX = obj.simDB.getSimFeatureExtraction(...
                                    simList{i}.sessionID, ...
                                    simList{i}.simSetID, simList{i}.simID);
                simHasSpikes = simFX.hasSpikes;
                simStimulusLatency = simFX.stimulusLatency;
                simISIMean = simFX.mean_isi;
                runIndex = simFX.runIDX;

                %% Perform the subclass-specific comparison
                results{i} = simList{i}; %#ok<*AGROW>
                if xor(expHasSpikes, simHasSpikes)
                    results{i}.score1 = realmax('double');
                else
                    results{i}.score1 = ...
                        sqrt((simStimulusLatency - expStimulusLatency)^2 + ...
                             (expISIMean - simISIMean)^2);
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
                                results{i}.score5)
            end            
        end
    end
end
