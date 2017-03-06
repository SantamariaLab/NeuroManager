% investigationDB - a class that provides an interface to a database associated
% with a NeuroManager-based investigation. (investigation is a series of
% sessions combined into one).
classdef investigationDB < handle
    properties
        dbName;
        dbConn;
    end
    
    methods (Abstract)
        initialize(obj)
        addSession(obj)
        addMachine(obj)
        addSimulator(obj)
        addExpDataSet(obj)
        addIPV(obj)
        addSimulationRun(obj)
        addComparison(obj)
        getSessionComparisons(obj)
        getIPVFromRunIDX(obj)
        getRunDataFromRunIDX(obj)
    end
    
    methods
        % avoid authentication and error checking stuff for now
        % Don't see any way to get the database name preconfigured into the
        % data source, so we supply it here for use in dumping.
        function obj = investigationDB(dataSourceName, databaseName)
            obj.dbName = databaseName;
            obj.dbConn = ...
                database.ODBCConnection(dataSourceName,'david','Uni53mad');            
        end
        
        function save(obj, userName, dir, annotation)
            savePath = fullfile(dir, [obj.dbName annotation '.sql']);
            command = ['mysqldump -u ' userName ' --password=Uni53mad ' ...
                       obj.dbName ' > ' savePath]
            [status,cmdout] = system(command)
        end
        
        function load(obj, userName, dumpPath)
            command = ['mysql -u ' userName ' --password=Uni53mad ' ...
                       obj.dbName ' < ' dumpPath]
            [status,cmdout] = system(command)
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