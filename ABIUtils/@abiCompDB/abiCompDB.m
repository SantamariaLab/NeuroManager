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
        % These must match the ipvs table definition in setIpvsTableCmd.m.
        % Override for specific investigations.  Here we don't know what
        % the pXX are, so we assume they are (longish) strings. Override
        % this class to redefine the table or to use the pXX differently.
        function ipvIndex = ...
                    addIPV(obj, expDataSetIndex, ...
                           tstop, tstep, taum, p04Str, p05Str, rM, ...
                           vRest, thresholdHeight, spikeHeight, p10Str, ...
                           stimCode, p12Str, stimulusStartTime, ...
                           pulseWidth, pulseCurrent, ...
                           p16Str, p17Str, p18Str, p19Str, p20Str, p21Str)
            colnames = {'ipvIDX', 'expDataSetIDX', 'tstop', 'tstep', 'taum', ...
                        'p04', 'p05', 'rM', 'vRest', 'thresholdHeight', ...
                        'spikeHeight', 'p10', 'stimulusType', 'p12', ...
                        'stimulusStartTime', 'pulseWidth', 'pulseCurrent', ...
                        'p16', 'p17', 'p18', 'p19', 'p20', 'p21'};
            coldata = ...
               {num2str(expDataSetIndex), num2str(tstop), num2str(tstep), ...
                num2str(taum), p04Str, ...
                p05Str, num2str(rM), ...
                num2str(vRest), num2str(thresholdHeight), ...
                num2str(spikeHeight), p10Str, ...
                ['''' stimCode ''''], ...
                p12Str, num2Str(stimulusStartTime), ...
                num2str(pulseWidth), num2str(pulseCurrent), ...
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
        % This approach depends on featDat matching the table definition in
        % content (but order not important); also puts the fx key into the
        % identified simulationRun. 
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
            curs = exec(obj.dbConn, insertStr); %#ok<NASGU>
            
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







