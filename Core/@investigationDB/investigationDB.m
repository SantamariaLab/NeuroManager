% investigationDB - a class that provides a minimal interface to a database
% associated with a NeuroManager-based investigation. (investigation is a
% series of sessions combined into one).
% Kept simple for flexibility.  Generally a {} or {'No data'} return means
% a failure, while a struct or scalar return means success (with
% accompanying data).
% Note: a full treatment of possible MySQL errors is beyond the scope of
% this project. For perspective, please see 
% https://dev.mysql.com/doc/refman/5.6/en/error-messages-server.html
classdef investigationDB < handle
    properties (Access=protected)
        dbSource;
        dbName;
        dbConn;
        dbUserName;
        dbPassword;
        tableList;
        createSessionsTableCmd;
        createMachinesTableCmd;
        createSimulatorsTableCmd;
        createExpDataSetsTableCmd;
        createComparisonsTableCmd;
        createSimFeatureExtractionsCmd;
        createIpvsTableCmd;
        createSimulationRunsTableCmd;
    end

    methods (Access=private)
        setTableCreateCmds(obj)
    end

    methods (Access=protected)
        setSimFeatureExtractionsCmd(obj)
        setIpvsTableCmd(obj)
        setSimulationRunsTableCmd(obj)

        %% createTable
        function result = createTable(obj, tableName)
            switch(tableName)
                case 'sessions'
                    mySQLcmd = obj.createSessionsTableCmd;
                case 'machines'
                    mySQLcmd = obj.createMachinesTableCmd;
                case 'simulators'
                    mySQLcmd = obj.createSimulatorsTableCmd;
                case 'simFeatureExtractions'
                    mySQLcmd = obj.createSimFeatureExtractionsCmd;
                case 'expDataSets'
                    mySQLcmd = obj.createExpDataSetsTableCmd;
                case 'ipvs'
                    mySQLcmd = obj.createIpvsTableCmd;
                case 'simulationRuns'
                    mySQLcmd = obj.createSimulationRunsTableCmd;
                case 'comparisons'
                    % Create comparisons table
                    mySQLcmd = obj.createComparisonsTableCmd;
                otherwise
                    error(['Bad tablename received by createTable:' tableName])
            end
            exec(obj.dbConn, mySQLcmd);
            result = true;
        end
        
        %% dropTable
        function dropTable(obj, tableName)
            mySQLcmd = ['DROP TABLE ' tableName];
            exec(obj.dbConn, mySQLcmd);
        end
        
        % Dropping done in reverse order because of foreign key
        % requirements
        function dropAllTables(obj)
            mySQLcmd = ['SET FOREIGN_KEY_CHECKS=0;'];
            exec(obj.dbConn, mySQLcmd);
            for i=length(obj.tableList):-1:1
                obj.dropTable(obj.tableList{i});
            end
            mySQLcmd = ['SET FOREIGN_KEY_CHECKS=1;'];
            exec(obj.dbConn, mySQLcmd);
        end

        %% createAllTables
        function result = createAllTables(obj)
            for i=1:length(obj.tableList)
                result = obj.createTable(obj.tableList{i});
                if ~result
                    return;
                end
            end
        end
        
    end

    methods
        %% Constructor
        function obj = investigationDB(dataSourceName, databaseName, ...
                                       userName, password)
            obj.dbSource = dataSourceName;
            obj.dbName = databaseName;
            obj.dbUserName = userName;
            obj.dbPassword = password;
            obj.dbConn = ...
               database.ODBCConnection(dataSourceName, ...
                                       obj.dbUserName, obj.dbPassword);            
            % These must be listed in order of table creation due to the
            % requirements of foreign key constraints; dropping will be 
            % done in reverse order. Sub classes can extend this as
            % desired.
            obj.tableList = {'sessions', 'machines', 'simulators', ...
                             'expDataSets', 'ipvs', ...
                             'simFeatureExtractions',  ...
                             'simulationRuns', 'comparisons'};
            obj.setBasicTableCreateCmds();
            obj.setIpvsTableCreateCmd();
            obj.setSimFeatureExtractionsTableCreateCmd();
            obj.setSimulationRunsTableCreateCmd();
        end

        %% initialize
        function result = initialize(obj)
            obj.dropAllTables();
            result = obj.createAllTables();
        end
        
        %% addSession 
        function sessionIndex = ...
                   addSession(obj, sessionID, customDir, simSpecFileDir, ...
                              modelFileDir, simResultsDir)
            colnames = {'sessionIDX', 'dateTime', 'customDir', ...
                        'simSpecFileDir', 'modelFileDir', 'simResultsDir'};
            coldata = {sessionID, ...
                       strrep(customDir,        '\', '/'), ...
                       strrep(simSpecFileDir,   '\', '/'), ...
                       strrep(modelFileDir,     '\', '/'), ...
                       strrep(simResultsDir,    '\', '/')};
            insertStr = ['insert into sessions (' ...
                         strjoin(colnames, ', ') ') values(0, ''' ...
                         strjoin(coldata, ''', ''') ''')'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, insertStr);
            cm = curs.Message;
            if ~isempty(strfind(cm, 'Error')) %#ok<*STREMP>
                close(curs);
                sessionIndex = {};
                return;
            end
            close(curs);
            
            % Get the new session's automatically assigned index
            % Reference:
            % https://www.mathworks.com/matlabcentral/answers/
            % 93959-how-can-the-primary-key-of-the-last-record-that-was-inserted-
            % into-a-database-using-the-fastinsert-co
            q = ['select sessionIDX from sessions ' ...
                  'WHERE sessionIDX = @@IDENTITY'];
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            temp = curs.Data;
            sessionIndex = temp.sessionIDX;
            close(curs);
        end
        
        %% addMachine 
        function machineIndex = addMachine(obj, name, resourceType)
            % Check for duplicates
            selStr = ['SELECT * FROM machines WHERE ' ...
                      'name=' ['"' name '"'] ' AND ' ...
                      'resourceType=' ['"' resourceType '"']];
            curs = exec(obj.dbConn, selStr);
            curs = fetch(curs);
            % If doesn't exist, add the entry
            if iscell(curs.Data) && strcmp(curs.Data{1}, 'No Data')
                close(curs);
                colnames = {'machineIDX', 'name', 'resourceType'};
                coldata = {name, resourceType};
                insertStr = ['insert into machines (' ...
                             strjoin(colnames, ', ') ') values(0, ''' ...
                             strjoin(coldata, ''', ''') ''')'];
                setdbprefs('DataReturnFormat','structure');
                curs = exec(obj.dbConn, insertStr);
                cm = curs.Message;
                if ~isempty(strfind(cm, 'Error')) %#ok<*STREMP>
                    close(curs);
                    machineIndex = {};
                    return;
                end
                close(curs);

                % Get the new index
                q2 = ['select machineIDX from machines ' ...
                      'WHERE machineIDX=@@IDENTITY'];
                curs = exec(obj.dbConn, q2);
                curs = fetch(curs);
                temp = curs.Data;
                machineIndex = temp.machineIDX;
                close(curs);
            else
                % Already exists, so just return the existing index
                machineIndex = curs.Data.machineIDX;
                close(curs);
            end
        end

        %% addSimulator 
        function simIDX = addSimulator(obj, machineIndex, name, type, version)
            % Check for duplicates
            selStr = ['SELECT * FROM simulators WHERE ' ...
                      'name=' ['"' name '"'] ' AND ' ...
                      'type=' ['"' char(type) '"'] ' AND ' ...
                      'version=' ['"' version '"']];
            curs = exec(obj.dbConn, selStr);
            curs = fetch(curs);
            % If doesn't exist, add the entry
            if iscell(curs.Data) && strcmp(curs.Data{1}, 'No Data')
                close(curs);
                colnames = {'simulatorIDX', 'machineIDX', 'name', ...
                            'type', 'version'};
                machineIndexStr = num2str(machineIndex);
                coldata = {machineIndexStr, name, char(type), version};
                insertStr = ['insert into simulators (' ...
                             strjoin(colnames, ', ') ') values(0, ''' ...
                             strjoin(coldata, ''', ''') ''')'];
                setdbprefs('DataReturnFormat','structure');
                curs = exec(obj.dbConn, insertStr);
                cm = curs.Message;
                if ~isempty(strfind(cm, 'Error')) %#ok<*STREMP>
                    close(curs);
                    simIDX = {};
                    return;
                end
                close(curs);
                
                q = ['select simulatorIDX from simulators ' ...
                     'WHERE simulatorIDX=@@IDENTITY'];
                curs = exec(obj.dbConn, q);
                curs = fetch(curs);
                simIDX = curs.Data.simulatorIDX;
                close(curs);
            else
                % Already exists, so just return the existing index
                simIDX = curs.Data.simulatorIDX;
                close(curs);
            end
        end

        %% addExpDataSet 
        % Do nothing if the addition has already been done.
        function expDataSetIndex = ...
                    addExpDataSet(obj, specNum, expNum, sampRate, ...
                                  stimulusType, expP2, expP3, expP4, ...
                                  expP5, expP6, expP7)
            % Test for existence
            selStr = ['SELECT * FROM expDataSets WHERE ' ...
                      'expSpecimenID=' num2str(specNum) ' AND ' ...
                      'expExperimentID=' num2str(expNum)];
            curs = exec(obj.dbConn, selStr);
            curs = fetch(curs);
            % If doesn't exist, add the entry
            if iscell(curs.Data) && strcmp(curs.Data{1}, 'No Data')
                close(curs);

                % Add the entry
                colnames = {'expDataSetIDX', 'expSpecimenID', ...
                            'expExperimentID', 'samplingRate', ...
                            'expP1', 'expP2', 'expP3', 'expP4', ...
                            'expP5', 'expP6', 'expP7'};
                coldata = {num2str(specNum), num2str(expNum), ...
                           num2str(sampRate), stimulusType, ...
                           num2str(expP2), num2str(expP3), num2str(expP4), ...
                           num2str(expP5), num2str(expP6), num2str(expP7)};
                columnStr = [strjoin(colnames, ', ') ...
                             ') values(0, ''' strjoin(coldata, ''', ''') ''''];
                insertStr = ['insert into expDataSets (' columnStr ')'];
                setdbprefs('DataReturnFormat','structure');
                curs = exec(obj.dbConn, insertStr);
                cm = curs.Message;
                if ~isempty(strfind(cm, 'Error')) %#ok<*STREMP>
                    close(curs);
                    expDataSetIndex = {};
                    return;
                end
                close(curs);

                q = ['select expDataSetIDX from expDataSets ' ...
                      'WHERE expDataSetIDX = @@IDENTITY'];
                curs = exec(obj.dbConn, q);
                curs = fetch(curs);
                expDataSetIndex = curs.Data.expDataSetIDX;
                close(curs);
            else
                % If it does exist, return the existing index
                expDataSetIndex = curs.Data.expDataSetIDX;
                close(curs);
            end
        end

        %% addIPV
        % This works with the above table definition and should be
        % overridden if the table creation is overridden.
        function ipvIndex = ...
                    addIPV(obj, expDataSetIndex, ...
                    p01Str, p02Str, p03Str, p04Str, p05Str, ...
                    p06Str, p07Str, p08Str, p09Str, p10Str, ...
                    p11Str, p12Str, p13Str, p14Str, p15Str, ...
                    p16Str, p17Str, p18Str, p19Str, p20Str, ...
                    p21Str)
            colnames = {'p01', 'p02', 'p03', 'p04', 'p05', ...
                        'p06', 'p07', 'p08', 'p09', 'p10', ...
                        'p11', 'p12', 'p13', 'p14', 'p15', ...
                        'p16', 'p17', 'p18', 'p19', 'p20', ...
                        'p21'};
            coldata = ...
               {num2str(expDataSetIndex), ...
                p01Str, p02Str, p03Str, p04Str, p05Str, ...
                p06Str, p07Str, p08Str, p09Str, p10Str, ...
                p11Str, p12Str, p13Str, p14Str, p15Str, ...
                p16Str, p17Str, p18Str, p19Str, p20Str, ...
                p21Str};
            insertStr = ['insert into ipvs (' ...
                         strjoin(colnames, ', ') ') values(0, ' ...
                         strjoin(coldata, ', ') ')'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, insertStr);
            cm = curs.Message;
            if ~isempty(strfind(cm, 'Error')) %#ok<*STREMP>
                close(curs);
                ipvIndex = {};
                return;
            end
            close(curs);

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
                        'timeFilename', ...
                        'other01Filename', ...
                        'other02Filename', ...
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
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, insertStr);
            cm = curs.Message;
            if ~isempty(strfind(cm, 'Error')) %#ok<*STREMP>
                close(curs);
                runIndex = {};
                return;
            end
            close(curs);
            
            q = ['select runIDX from simulationRuns ' ...
                 'WHERE runIDX = @@IDENTITY'];
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            runIndex = curs.Data.runIDX;
            close(curs);
        end
        
        %% addSimFeatureExtraction
        function fxIDX = ...
                addSimFeatureExtraction(obj, fxNumber, fxBool, runIDX)
            colnames = {'fxIDX', 'fxNumber', 'fxBool'};
            coldata = {num2str(fxNumber), ...
                       num2str(fxBool)};
            insertStr = ['insert into simFeatureExtractions (' ...
                         strjoin(colnames, ', ') ') values(0, ' ...
                         strjoin(coldata, ', ') ')'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, insertStr);
            cm = curs.Message;
            if ~isempty(strfind(cm, 'Error')) %#ok<*STREMP>
                close(curs);
                fxIDX = {};
                return;
            end
            close(curs);
            
            q = ['select fxIDX from simFeatureExtractions ' ...
                 'WHERE fxIDX = @@IDENTITY'];
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            fxIDX = curs.Data.runIDX;
            close(curs);
            
            % Update the corresponding simulationRun with the foreign key
            update(obj.dbConn, 'simulationRuns', {'fxIDX','state'}, ...
                   {fxIDX,'FULLYPROCESSED'}, ...
                   ['WHERE runIDX=' num2str(runIDX)]);
        end
        
        %% addComparison 
        % cell return means failure to add.
        function compIndex = addComparison(obj, runIndex, cmpType, ...
                                    score1, score2, score3, score4, score5)
                % Massage the results for database insertion
                if isnan(score1)
                    score1Str = 'NULL';
                else
                    % precision is important to get by MySQL input
                    score1Str = num2str(score1, 14);
                end 
                if isnan(score2)
                    score2Str = 'NULL';
                else
                    score2Str = num2str(score2, 14);
                end 
                if isnan(score3)
                    score3Str = 'NULL';
                else
                    score3Str = num2str(score3, 14);
                end 
                if isnan(score4)
                    score4Str = 'NULL';
                else
                    score4Str = num2str(score4, 14);
                end 
                if isnan(score5)
                    score5Str = 'NULL';
                else
                    score5Str = num2str(score5, 14);
                end 
                
                % Handle infinities
                % (not implemented yet)
                
                % Add the comparison to the database
                colnames = {'cmpIDX', 'runIDX', ...
                            'cmpType', ...
                            'score1', 'score2', 'score3', ...
                            'score4', 'score5'};
                coldata = {num2str(runIndex), ...
                           ['''' cmpType ''''], ...
                           score1Str, score2Str, score3Str, ...
                           score4Str, score5Str};
                insertStr = ['insert into comparisons (' ...
                             strjoin(colnames, ', ') ') values(0, ' ...
                             strjoin(coldata, ', ') ')'];
                setdbprefs('DataReturnFormat','structure');
                curs = exec(obj.dbConn, insertStr);
                cm = curs.Message;
                if ~isempty(strfind(cm, 'Error')) %#ok<*STREMP>
                    close(curs);
                    compIndex = {};
                    return;
                end
                close(curs);
            
                q = ['select cmpIDX from comparisons ' ...
                     'WHERE cmpIDX = @@IDENTITY'];
                curs = exec(obj.dbConn, q);
                curs = fetch(curs);
                compIndex = curs.Data.cmpIDX;
                close(curs);
        end
        
        %% getSimFeatureExtraction
        % If returns cell, not found in database.  If struct, has the row.
        function featExtr = getSimFeatureExtraction(obj, sessionID, ...
                                                         simSetID, simID)
            q = ['SELECT simFeatureExtractions.*, simulationRuns.runIDX ' ...
                 'FROM ((simFeatureExtractions INNER JOIN simulationRuns ' ...
                 'ON simFeatureExtractions.fxIDX=simulationRuns.runIDX) ' ...
                 'INNER JOIN sessions ' ...
                 'ON simulationRuns.sessionIDX=sessions.sessionIDX) ' ...
                 'WHERE sessions.dateTime=' '"' sessionID '"' ...
                     ' AND simulationRuns.simID=' '"' simID '" ' ...
                     ' AND simulationRuns.simSetID=' '"' simSetID '" ' ...
                     ';'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            featExtr = curs.Data;
            close(curs);
        end

        %% getIPVFromRunIDX
        function ipvData = getIPVFromRunIDX(obj, runIDX)
            q = ['SELECT ipvs.* FROM (ipvs INNER JOIN simulationRuns ' ...
                 'ON ipvs.ipvIDX=simulationRuns.ipvIDX) ' ...
                 'WHERE simulationRuns.runIDX=' num2str(runIDX) ';'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            ipvData = curs.Data;
            close(curs);
        end
        
        %% getRunDataFromRunIDX 
        function runData = getRunDataFromRunIDX(obj, runIDX)
            q = ['SELECT simulationRuns.* FROM simulationRuns ' ...
                 'WHERE simulationRuns.runIDX=' num2str(runIDX) ';'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            runData = curs.Data;
            close(curs);
        end        
        
        %% getSimulationRunDataFromCmpIDX
        function simRunData = getSimulationRunDataFromCmpIDX(obj, cmpIDX)
            q = ['SELECT simulationRuns.* ' ...
                 'FROM comparisons INNER JOIN simulationRuns ' ...
                 'ON comparisons.runIDX=simulationRuns.runIDX ' ...
                 'WHERE comparisons.cmpIDX=' num2str(cmpIDX) ';'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            simRunData = curs.Data;
            close(curs)
        end
    
        %% getExpDataSet
        function expDataSet = getExpDataSet(obj, specNum, expNum)
            setdbprefs('DataReturnFormat','structure');
            whereStr = ...
                ['where expDataSets.expSpecimenID=' num2str(specNum) ...
                 ' and expDataSets.expExperimentID=' num2str(expNum)];
            curs = exec(obj.dbConn, ...
                        ['select * from expDataSets ' whereStr]);
            curs = fetch(curs);
            expDataSet = curs.Data;
            close(curs);
        end
        
        %% getExpDataSetFromRunIDX
        function expDataSet = getExpDataSetFromRunIDX(obj, runIDX)
            q = ['SELECT expDataSets.expSpecimenID, expDataSets.expExperimentID ' ...
                 'FROM ((simulationRuns INNER JOIN ipvs' ...
                 ' ON simulationRuns.ipvIDX=ipvs.ipvIDX)' ...
                 ' INNER JOIN expDataSets ' ...
                 'ON ipvs.expDataSetIDX=expDataSets.expDataSetIDX) ' ...
                 'WHERE simulationRuns.runIDX=' num2str(runIDX) ';'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            expDataSet = curs.Data;
            close(curs);
        end 

        %% getAllExpDataSets
        function expDataSetList = getAllExpDataSets(obj)
            setdbprefs('DataReturnFormat','structure');
            whereStr = '';
            curs = exec(obj.dbConn, ...
                        ['select * from expDataSets ' whereStr]);
            curs = fetch(curs);
            expDataSetList = curs.Data;
            close(curs);
        end
  
        %% getSessionComparisons 
        function comps = getSessionComparisons(obj, sessionID)
            q = ['SELECT comparisons.runIDX,' ...
                 'comparisons.score1, ' ...
                 'comparisons.score2, ' ...
                 'comparisons.score3, ' ...
                 'comparisons.score4, ' ...
                 'comparisons.score5, ' ...
                 'simulationRuns.simID ' ...
                 'FROM ((comparisons INNER JOIN simulationRuns ON ' ...
                 'comparisons.runIDX=simulationRuns.runIDX) INNER JOIN ' ...
                 'sessions ON simulationRuns.sessionIDX=sessions.sessionIDX) ' ...
                 'WHERE sessions.dateTime="' sessionID '";'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            comps = curs.Data;
            close(curs);
        end
        
        %% updateSessionSimSpecDir
        function updateSessionSimSpecDir(obj, sessionIndex, newDir)
            % Update the entry
            colnames = {'simSpecFileDir'};
            coldata = {newDir};
            whereStr = ['WHERE sessionIDX=' num2str(sessionIndex)];
            update(obj.dbConn, 'sessions', colnames, coldata, whereStr);
        end
            
        %% getDataSourceName
        function name = getDataSourceName(obj)
            name = obj.dbSource;
        end
        
        %% getDatabaseName
        function name = getDatabaseName(obj)
            name = obj.dbName;
        end
        
        %% getSimulationRunIndex
        function runIDX = getSimulationRunIndex(obj, simID, simSetID, ...
                                                     sessionID)
            q = ['SELECT simulationRuns.runIDX from simulationRuns' ...
                 ' INNER JOIN sessions ON' ...
                 ' simulationRuns.sessionIDX=sessions.sessionIDX' ...
                 ' WHERE sessions.dateTime="' sessionID ...
                 '" AND simulationRuns.simSetID="' ...
                 simSetID '" AND' ...
                 ' simulationRuns.simID="' simID '";'];
            setdbprefs('DataReturnFormat','structure');
            curs = exec(obj.dbConn, q);
            cm = curs.Message;
            if ~isempty(strfind(cm, 'Error')) %#ok<*STREMP>
                close(curs);
                runIDX = {};
                return;
            end
            curs = fetch(curs);
            temp = curs.Data;
            if iscell(temp) 
                runIDX = 0;
            else
                runIDX = temp.runIDX;
            end
            close(curs);
        end
        
        %% save
        function [status,cmdout] = save(obj, userName, dir, annotation)
            savePath = fullfile(dir, [obj.dbName annotation '.sql']);
            command = ['mysqldump -u ' userName ...
                       ' --password=' obj.dbPassword ' ' ...
                       obj.dbName ' > ' savePath];
            [status,cmdout] = system(command);
        end
        
        %% load
        function [status,cmdout] = load(obj, userName, dumpPath)
            command = ['mysql -u ' userName ...
                       ' --password=' obj.dbPassword ' ' ...
                       obj.dbName ' < ' dumpPath];
            [status,cmdout] = system(command);
        end
        
        %% getConn
        function conn = getConn(obj)
            conn = obj.dbConn;
        end
        
        %% closeConn
        function closeConn(obj)
            close(obj.dbConn);
        end
        
        %% delete
        function delete(obj)
            close(obj.dbConn);
        end
        
    end
end
