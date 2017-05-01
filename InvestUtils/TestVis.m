%% Setup
clc
projDir = 'C:\Users\David\Dropbox\Documents\SantamariaLab\Projects\'; 
addpath([projDir 'ProjNeuroMan\NeuroManager\Core']);
addpath([projDir 'Fractional\ABI-FLIF\ABICellSurvey\src']);
addpath([projDir 'ABAtlas\ABIApiML']);

%% Connect with the experimental data (ABI) database
abiDatabaseName = 'ABICellSurvey';
disp(['Connecting to abi database ' abiDatabaseName '.']);
abiDBConn = database.ODBCConnection(abiDatabaseName,'david','Uni53mad');

%% Connect to the inv database
addpath(['C:/Users/David/Dropbox/Documents/SantamariaLab/Projects/' ...
         'ProjNeuroMan/NeuroManager/InvestDBUtils'])
simsDataSourceName = 'InvDBTest';
simsDatabaseName = 'invdbtest';
disp(['Connecting to investigation database ' simsDatabaseName ...
           ' using data source ' simsDataSourceName '.']);
invDB = abiCompDB(simsDataSourceName, simsDatabaseName, ...
                  'david', 'Uni53mad');
              
%% Set up comparator
% Deal with need to specify Cmp03 when should not be necessary
cmp = Cmp03(abiDBConn, invDB);
              
%% Visualize comparisons
cmp.visComparison(5, true)
