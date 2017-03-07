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
    end
    
    methods (Abstract)
        initialize(obj)
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

        function save(obj, userName, dir, annotation)
            savePath = fullfile(dir, [obj.dbName annotation '.sql']);
            command = ['mysqldump -u ' userName ...
                       ' --password=' obj.dbPassword ' ' ...
                       obj.dbName ' > ' savePath];
            [~, ~] = system(command);
        end

        function load(obj, userName, dumpPath)
            command = ['mysql -u ' userName ...
                       ' --password=' obj.dbPassword ' ' ...
                       obj.dbName ' < ' dumpPath];
            [~, ~] = system(command);
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
