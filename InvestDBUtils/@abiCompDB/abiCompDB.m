% abiCompDB - a subclass for dealing with the ABI database

classdef abiCompDB < investigationDB
    methods (Access=protected)
        setSimFeatureExtractionsCmd(obj)
        setIpvsTableCmd(obj)
        setSimulationRunsTableCmd(obj)
    end
    
    methods
        %% abiCompDB
        function obj = abiCompDB(dataSourceName, databaseName, ...
                                 userName, password)
            obj = obj@investigationDB(dataSourceName, databaseName, ...
                                      userName, password);
            % These are subclass-specific
            obj.setSimFeatureExtractionsCmd();
            obj.setIpvsTableCmd();
            obj.setSimulationRunsTableCmd();
        end
        
        %% addIPV 
        % This could be genericized someday but might lose clarity
        function ipvIndex = ...
                    addIPV(obj, expDataSetIndex, ...
                           tstop, tstep, taum, p04, p05, rM, ...
                           vRest, thresholdHeight, spikeHeight, p10, ...
                           stimCode, p12, stimulusStartTime, pulseWidth, ...
                           pulseCurrent, p16, p17, p18, p19, p20, p21)
            colnames = {'ipvIDX', 'expDataSetIDX', 'tstop', 'tstep', 'taum', 'p04', ...
                        'p05', 'rM', 'vRest', 'thresholdHeight', ...
                        'spikeHeight', 'p10', 'stimulusType', 'p12', ...
                        'stimulusStartTime', 'pulseWidth', 'pulseCurrent', ...
                        'p16', 'p17', 'p18', 'p19', 'p20', 'p21'};
            % All this massaging needs to be designed/rewritten
            if isnan(p04)
                p04Str = 'NULL';
            else
                p04Str = num2str(p04);
            end
            if isnan(p05)
                p05Str = 'NULL';
            else
                p05Str = num2str(p05);
            end
            if isnan(p12)
                p12Str = 'NULL';
            else
                p12Str = num2str(p12);
            end
            if isnan(stimulusStartTime)
                stimulusStartTimeStr = 'NULL';
            else
                stimulusStartTimeStr = num2str(stimulusStartTime);
            end
            if isnan(pulseWidth)
                pulseWidthStr = 'NULL';
            else
                pulseWidthStr = num2str(pulseWidth);
            end
            if isnan(pulseCurrent)
                pulseCurrentStr = 'NULL';
            else
                pulseCurrentStr = num2str(pulseCurrent);
            end
            if isnan(p16)
                p16Str = 'NULL';
            else
                p16Str = num2str(p16);
            end
            if isnan(p17)
                p17Str = 'NULL';
            else
                p17Str = num2str(p17);
            end
            if isnan(p18)
                p18Str = 'NULL';
            else
                p18Str = num2str(p18);
            end
            if isnan(p19)
                p19Str = 'NULL';
            else
                p19Str = num2str(p19);
            end
            if isnan(p20)
                p20Str = 'NULL';
            else
                p20Str = num2str(p20);
            end
            if isnan(p21)
                p21Str = 'NULL';
            else
                p21Str = num2str(p21);
            end
            
            %%
            coldata = ...
               {num2str(expDataSetIndex), num2str(tstop), num2str(tstep), ...
                num2str(taum), p04Str, ...
                p05Str, num2str(rM), ...
                num2str(vRest), num2str(thresholdHeight), ...
                num2str(spikeHeight), p10, ...
                ['''' stimCode ''''], ...
                p12Str, stimulusStartTimeStr, ...
                pulseWidthStr, pulseCurrentStr, ...
                p16Str, p17Str, p18Str, p19Str, p20Str, p21Str};
            insertStr = ['insert into ipvs (' ...
                         strjoin(colnames, ', ') ') values(0, ' ...
                         strjoin(coldata, ', ') ')'];
            exec(obj.dbConn, insertStr);
            
            q = ('select ipvIDX from ipvs WHERE ipvIDX = @@IDENTITY');
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            ipvIndex = curs.Data.ipvIDX;
            close(curs);
        end
        
        %% addSimulationRun 
        % Assumes (for now) that simulation hasn't been assigned to a
        % simulator, run, or had feature extraction done.
        function runIndex = ...
                addSimulationRun(obj, ipvIDX,  ...
                    sessionIDX, simSetID, simID, simSampleRate, ...
                    simulationDuration)
            colnames = {'runIDX', 'ipvIDX', 'simulatorIDX', ...
                        'sessionIDX', 'fxIDX', ...
                        'simSetID', 'simID', 'simSampleRate', ...
                        'simulationDuration', 'state', ...
                        'simSpecFilename', 'resultsDir', ...
                        'stimulusFilename', 'voltageFilename', ...
                        'spikeMarkerFilename', ...
                        'timeFilename', 'fxFilename', ...
                        'runtime', 'result'};
            coldata = {num2str(ipvIDX), ...
                       'NULL', ...
                       num2str(sessionIDX),...
                       'NULL', ...
                       ['''' simSetID ''''], ...
                       ['''' simID ''''], ...
                       num2str(simSampleRate), ...
                       num2str(simulationDuration), ...
                       ['''' 'UNRUN' ''''], ...
                       ['''' simSetID '_COPY_DO_NOT_EDIT.txt'''], ...
                       'NULL', 'NULL', 'NULL', 'NULL', 'NULL', ...
                       'NULL', 'NULL', 'NULL'};
            insertStr = ['insert into simulationRuns (' ...
                         strjoin(colnames, ', ') ') values(0, ' ...
                         strjoin(coldata, ', ') ')'];
            exec(obj.dbConn, insertStr);
            
            q = ['select runIDX from simulationRuns ' ...
                 'WHERE runIDX = @@IDENTITY'];
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            runIndex = curs.Data.runIDX;
            close(curs);
        end
        
        %% addSimFeatureExtraction
        % This approach depends on featDat matching the table definition;
        % also puts the fx key into the identified simulationRun.
        function fxIDX = ...
                addSimFeatureExtraction(obj, featDat, runIDX)
            fns = fieldnames(featDat);
            colnames = cell(length(fns)+1, 1);
            colnames{1} = 'fxIDX';
            coldata = cell(length(fns),1);
            for i = 1:length(fns)
                colnames{i+1} = fns{i};
                temp = featDat.(fns{i});
                if islogical(temp)
                    if(temp)
                        coldata{i} = '1';
                    else
                        coldata{i} = '0';
                    end
                elseif ischar(temp)
                    coldata{i} = temp;
                elseif isempty(temp)
                    coldata{i} = 'NULL';
                elseif isnumeric(temp)
                    coldata{i} = num2str(temp);
                else
                    coldata{i} = 'NULL';
                end
            end
            columnStr = [strjoin(colnames, ', ') ...
                         ') values(0, ' strjoin(coldata, ', ')];
            insertStr = ['insert into simFeatureExtractions (' columnStr ')'];
            exec(obj.dbConn, insertStr);
            
            q = ['select fxIDX from simFeatureExtractions ' ...
                 'WHERE fxIDX = @@IDENTITY'];
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            temp = curs.Data;
            fxIDX = temp.fxIDX;
            close(curs);
            
            % Update the corresponding simulationRun with the foreign key
            update(obj.dbConn, 'simulationRuns', {'fxIDX','state'}, ...
                   {fxIDX,'FULLYPROCESSED'}, ...
                   ['WHERE runIDX=' num2str(runIDX)]);
        end

        %% updateSimulationRun
        function updateSimulationRun(obj, runIDX, simulatorIDX, ...
                        resultsDir, stimulusFilename, voltageFilename, ...
                        spikeMarkerFilename, timeFilename, fxFilename, ...
                        simTime, simResult)
            colnames  = {'simulatorIDX', 'resultsDir', ...
                         'stimulusFilename', 'voltageFilename', ...
                         'spikeMarkerFilename', 'timeFilename', ...
                         'fxFilename', 'runtime', 'result'};
            coldata   = {simulatorIDX, resultsDir, ...
                         stimulusFilename, voltageFilename, ...
                         spikeMarkerFilename, timeFilename, ...
                         fxFilename, simTime, simResult};
            whereStr  = ['WHERE runIDX=' num2str(runIDX)];
            update(obj.dbConn, 'simulationRuns', ...
                   colnames, coldata, whereStr);
        end
                                
        %% delete
        function delete(obj)
            delete@investigationDB(obj);
        end
        
    end
end








