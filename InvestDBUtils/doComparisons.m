function results = doComparisons(cmpType, specNum, expNum, sessID, ...
                                 simSetID, simIDList, simDBConn, abiDBConn)
                   
    % ignore type for now
    
    % Get the experimental features
    % (here: 
    % hasSpikes, (from experimentFXs)
    % stimulusLatency = latency (from experimentFXs) since analysis_start
    %                   was same as stimulus start (for LS, anyway)
    %                   ADD STIMULUS LATENCY TO ABICELLSURVEY, THEN
    %                   ADJUST ABICELLSURVEY TO HAVE CORRECT STIMULUS START
    %                   FOR EACH STIMULUS TYPE
    % mean_isi (from experimentFXs)
    q = ['SELECT experimentFXs.hasSpikes, ' ...
         'experimentFXs.latency, experimentFXs.mean_isi ' ...
         'FROM ((experimentFXs INNER JOIN experiments ' ...
         'ON experimentFXs.id=experiments.expFXID) ' ...
         'INNER JOIN specimens ' ...
         'ON experiments.specimenIDX=specimens.id) ' ...
         'WHERE specimens.abiSpecimenID=' num2str(specNum) ...
         ' AND experiments.abiExperimentID=' num2str(expNum) ';'];
    setdbprefs('DataReturnFormat','structure');
    curs = exec(abiDBConn, q);
    curs = fetch(curs);
    temp = curs.Data;
    expHasSpikes = temp.hasSpikes;
    expStimulusLatency = temp.latency;
    expMeanISI = temp.mean_isi;
%     disp(['expHasSpikes = ' num2str(expHasSpikes) ...
%           ', expStimulusLatency = ' num2str(expStimulusLatency) ...
%           ', expMeanISI = ' num2str(expMeanISI)])
      
    % For each simulation in the list, grab its relevant features then
    % apply the measure to the two and put the result in the output struct
    % (and database)
    for i=1:length(simIDList)
        % Get the features
        q = ['SELECT simFeatureExtractions.hasSpikes, ' ...
             'simFeatureExtractions.latency, ' ...
             'simFeatureExtractions.mean_isi, ' ...
             'simulationRuns.runIDX ' ...
             'FROM ((simFeatureExtractions INNER JOIN simulationRuns ' ...
             'ON simFeatureExtractions.fxIDX=simulationRuns.runIDX) ' ...
             'INNER JOIN sessions ' ...
             'ON simulationRuns.sessionIDX=sessions.sessionIDX) ' ...
             'WHERE sessions.dateTime=' '"' sessID '"' ...
             ' AND simulationRuns.simID=' '"' simIDList{i} '" ' ...
             ' AND simulationRuns.simSetID=' '"' simSetID '" ' ...
             ';'];
        setdbprefs('DataReturnFormat','structure');
        curs = exec(simDBConn, q);
        curs = fetch(curs);
        temp = curs.Data;
        simHasSpikes = temp.hasSpikes;
        simStimulusLatency = temp.latency;
%         simStimulusLatency = temp.stimulusLatency;
        simMeanISI = temp.mean_isi;
        runIDX = temp.runIDX;
        disp(['simID=' simIDList{i} ': ' ...
            'simHasSpikes = ' num2str(simHasSpikes) ...
              ', simStimulusLatency = ' num2str(simStimulusLatency) ...
              ', simMeanISI = ' num2str(simMeanISI)]);
%         results(i) = []; %#ok<*AGROW>
        results(i).simID = simIDList{i}; %#ok<*AGROW>
        if xor(expHasSpikes, simHasSpikes)
            results(i).score1 = Inf;
        else
            results(i).score1 = ...
                sqrt((simStimulusLatency - expStimulusLatency)^2 + ...
                     (expMeanISI - simMeanISI)^2);
        end
        
        results(i).score2 = NaN;
        results(i).score3 = NaN;
        results(i).score4 = NaN;
        results(i).score5 = NaN;
        if isnan(results(i).score1)
            score1Str = 'NULL';
        else
            score1Str = num2str(results(i).score1);
        end 
        if isnan(results(i).score2)
            score2Str = 'NULL';
        else
            score2Str = num2str(results(i).score2);
        end 
        if isnan(results(i).score3)
            score3Str = 'NULL';
        else
            score3Str = num2str(results(i).score3);
        end 
        if isnan(results(i).score4)
            score4Str = 'NULL';
        else
            score4Str = num2str(results(i).score4);
        end 
        if isnan(results(i).score5)
            score5Str = 'NULL';
        else
            score5Str = num2str(results(i).score5);
        end 
        
        % Add the comparison to the database
        colnames = {'cmpIDX', 'runIDX', 'cmpType', ...
                    'score1', 'score2', 'score3', ...
                    'score4', 'score5'};
        coldata = {num2str(runIDX), ...
                   ['''' cmpType ''''], ...
                   score1Str, score2Str, score3Str, score4Str, score5Str};
        insertStr = ['insert into comparisons (' ...
                     strjoin(colnames, ', ') ') values(0, ' ...
                     strjoin(coldata, ', ') ')'];
        exec(simDBConn, insertStr);
    end
end
