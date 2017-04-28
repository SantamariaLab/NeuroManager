% investigationDB - a class that provides an interface to a database associated
% with a NeuroManager-based investigation. (investigation is a series of
% sessions combined into one).
classdef investigationDB < handle
    properties
        dbSource;
        dbName;
        dbConn;
        dbUserName;
        dbPassword;
        tableList;
    end
    
    methods (Abstract)
        createTable(obj)
        addSession(obj)
        addMachine(obj)
        addSimulator(obj)
        addExpDataSet(obj)
        getExpDataSet(obj)
        addIPV(obj)
        addSimulationRun(obj)
        getIPVFromRunIDX(obj)
        getRunDataFromRunIDX(obj)
    end
    
    methods
        % avoid authentication and error checking stuff for now
        % Don't see any way to get the database name preconfigured into the
        % data source, so we supply it here for use in dumping.
        function obj = investigationDB(dataSourceName, databaseName, ...
                                       userName, password)
            obj.dbSource = dataSourceName;
            obj.dbName = databaseName;
            obj.dbUserName = userName;
            obj.dbPassword = password;
            obj.dbConn = ...
               database.ODBCConnection(dataSourceName, ...
                                       obj.dbUserName, obj.dbPassword);            
        end

        function dropTable(tableName)
            mySQLcmd = ['DROP TABLE ' tableName];
            exec(obj.dbConn, mySQLcmd);
        end
        
        % Dropping done in reverse order because of foreign key
        % requirements
        function dropAllTables(obj)
            mySQLcmd = ['SET FOREIGN_KEY_CHECKS=0;'];
            exec(obj.dbConn, mySQLcmd);
            for i=length(obj.tableList):-1:1
                dropTable(obj.tableList{i})
            end
            mySQLcmd = ['SET FOREIGN_KEY_CHECKS=1;'];
            exec(obj.dbConn, mySQLcmd);
        end

        function result = initialize(obj)
            result = obj.dropAllTables();
            if result
                result = obj.createAllTables();
            end
        end
        
        function createAllTables(obj)
            for i=1:length(obj.tableList)
                createTable(obj.tableList{i});
            end
        end
        
        function name = getDataSourceName(obj)
            name = obj.dbSource;
        end
        
        function name = getDatabaseName(obj)
            name = obj.dbName;
        end
        
        function name = getUserName(obj)
            name = obj.dbUserName;
        end
        
        % just temporary
        function pw = getPassword(obj)
            pw = obj.dbPassword;
        end

        function [status,cmdout] = save(obj, userName, dir, annotation)
            savePath = fullfile(dir, [obj.dbName annotation '.sql']);
            command = ['mysqldump -u ' userName ...
                       ' --password=' obj.dbPassword ' ' ...
                       obj.dbName ' > ' savePath];
            [status,cmdout] = system(command);
        end

        function [status,cmdout] = load(obj, userName, dumpPath)
            command = ['mysql -u ' userName ...
                       ' --password=' obj.dbPassword ' ' ...
                       obj.dbName ' < ' dumpPath];
            [status,cmdout] = system(command);
        end

        function conn = getConn(obj)
            conn = obj.dbConn;
        end

        function closeConn(obj)
            close(obj.dbConn);
        end

        function delete(obj)
            close(obj.dbConn);
        end
    end
end
