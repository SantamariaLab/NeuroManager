%% Initial prep
clc
disp('Clearing variables, classes, and java. Please wait...');
clear; clear variables; clear classes; clear java;   %#ok<*CLJAVA,*CLCLS>

%%%
% voltages in mV; currents in pA; resistances in MOhms; times in msec
% rates in events/second; current in nA
%%%
myData = 'The full path to the userStaticData.ini file';
[nmAuthData, nmDirectorySet, userData] = loadUserStaticData(myData);

%% Set up a Neuromanager session
disp(['Starting the MMInvDB investigation']);
launchDir = pwd;
% The user creates this directory in advance to provide a home for the
% investigation.
investigationDir = fullfile(launchDir, 'MMInvDBInvestigation01');

% We are using three external (external to NeuroManager but on the user
% host computer) ABI-related code locations and need access to 
% them. The first is where the source files are from the ABICellSurvey
% repository.  The second is the host computer directory in which the files
% from the ABIApiML repository are located.  The third is the host location
% where the ABI NWB files are located that the user downloaded by hand or
% through use of the CellSurvey software. These directories are identified
% in userStaticData.ini and must be set by the user.
addpath(nmDirectorySet.abiCellSurveySrcDir);
addpath(nmDirectorySet.abiApiMLDir);
addpath(nmDirectorySet.localCellTypesDir);

% Set up NeuroManager with the MMInvDB simulator, using model files from
% the Miyasho model example
nmDirectorySet.customDir = launchDir;
nmDirectorySet.modelDir = fullfile(nmDirectorySet.nmMainDir,...
                                    'NeurSim', 'MiyashoMOD');
% So that MATLAB can locate the simulator superclass
% SimNeurPurkinjeMiyasho2001 
addpath(nmDirectorySet.modelDir); 
% Session results will be placed under the investigation directory
nmDirectorySet.resultsDir = investigationDir;
nmDirectorySet.simSpecFileDir = nmDirectorySet.resultsDir;

nm = NeuroManager(nmDirectorySet, nmAuthData, userData,...
                  'maxNumSimSpecParams', 21,...
                  'notificationsType', 'NONE', 'useDualKey', true,...
                  'isSingleMachine', false);

log = nm.getLog(); % To enable log additions from this script

% Copy the remote feature extraction files from common storage into the
% investigation for use. For now we don't have a special abiFX class for
% NeuroManager; we just put the fx files into the simulator's Addl Custom
% File list and copy them into that directory, ensuring one file source.
% Four of these files (ephys_extractor.py, ephys_features.py,
% extract_cell_features.py, and feature_extractor.py) are included in the
% NM files and come from ABI.  
featureExtractionFileList = {'__init__.py', ...
                             'ephys_extractor.py', ...
                             'ephys_features.py', ...
                             'extract_cell_features.py', ...
                             'feature_extractor.py', ...
                             'extractABIExpFeatures.m', ...
                             'STGFeatExtr.py'};  
 for i=1:length(featureExtractionFileList)
    sourceFile = fullfile(nm.getABIUtilsDir(), featureExtractionFileList{i});
	copyfile(sourceFile, launchDir);
 end
 % This file is part of the ABITools CellSurvey repository
 copyfile(fullfile(nmDirectorySet.abiCellSurveySrcDir, 'ABISweepFX.py'), ...
          launchDir);
 log.write(['ABI remote feature extraction files copied to ' launchDir]);
 
 %% Connect with the experimental data (ABI) database
abiDatabaseName = 'ABICellSurvey'; % Or whatever database name you have
log.write(['Connecting to abi database ' abiDatabaseName '.']);
% This is pre2017a syntax but valid
abiDBConn = database.ODBCConnection(abiDatabaseName, ...
                            userData.mysqlUsername, userData.mysqlPassword);

%% Attach the investigation database
% On Windows, set up using MATLAB's Database Toolbox Database Explorer app
simsDataSourceName = 'MMInvDB';
simsDatabaseName = 'mminvdb';
log.write(['Connecting to investigation database ' simsDatabaseName ...
           ' using data source ' simsDataSourceName '.']);
invDB = abiMMCompDB(simsDataSourceName, simsDatabaseName, ...
                    userData.mysqlUsername, userData.mysqlPassword);

% Reset or Load Database?
% !!!!!!!!!!!!!!!
resetInvestigationDatabase = true;   % !!!!!!!!!!!!!!!
% !!!!!!!!!!!!!!!

if resetInvestigationDatabase
    % Set up the new (for now) database for this run by cleaning out the
    % old one and rebuilding it.
    log.write(['Initializing investigation database ' simsDatabaseName '.']);
    invDB.initialize();
else
    % Load the latest database backup from the investigation dir
    slist = sort(string(ls(fullfile(investigationDir, ...
                             [simsDatabaseName '*.sql']))), 'descend'); %#ok<*UNRCH>
    buPath = fullfile(investigationDir, char(slist(1,:)));
    log.write(['Loading investigation database backup file ' buPath ...
        ' into investigation database ' simsDatabaseName '.']);
    invDB.load('david', buPath)  % fix authentication later
end
nm.attachInvestigationDatabase(investigationDir, invDB);

%% Move the SimSpecDir to the SimResults dir for the session so that the 
% SimSets we automatically construct will be placed with the session.  
d = nm.getSimResultsDir();
nm.setSimSpecFileDir(d);
nm.log.write(['SimSpec Directory changed to: ' nm.getSimSpecFileDir()]);
% SessionIndex was set by the attach function
invDB.updateSessionSimSpecDir(nm.getSessionIndex(), d);

%% Set simulator type and machine configuration
% A special simulator derived from the Sim_MiyashoMOD class
simulatorType = SimType.SIM_MMINVDB;  
nm.setSimulatorType(simulatorType);
MLCompileMachineInfoFile = 'MyCompileMachineInfo.json';
nm.setMLCompileServer(MLCompileMachineInfoFile);
nm.doMATLABCompilation();

numSimulators = 6;
nm.addClusterQueue('MyClusterInfo.json', 'General', ...
                   numSimulators, 'myRemoteWorkDir');
nm.printConfig();

%% Test communications, file transfers, and other compatibilities
if ~nm.verifyConfig()
    return;
end

%% Build the Simulators on the server
nm.constructMachineSet();

%% Experiment vs simulation sample rates
ABISamplingRate = 200000;   % experimental data samples per second
SimSamplingRate = 20000;    % simulation raw data samples per second

%% Select specimens and experiments
% Some of the ABI Specimens that have models associated with them
specimens = [484635029, ... % 01
             469801569, ... % 02
             469753383, ... % 03
             487667205];    % 04
specimenNum = specimens(03);    % Arbitrary choices
experimentNum = 51;             % (hero sweep for 469753383)

%% Grab the experimental features for that choice...
fxData = ABIFeatExtrData(abiDBConn);

%% Install the experimental features into the investigation database for 
% association with the ipvs
expData = fxData.getExpFXData(specimenNum, experimentNum);
specData = fxData.getSpecFXData(specimenNum);
expInfo = fxData.getExpInfo(specimenNum, experimentNum);
% ...and put them into the investigation database as a new expDataSet;
% the expPx values can be used as a source to generate the input parameter
% space for the simulations to be done
stimulusType = expInfo.stimulusType{1};
% threshold: ABI's "experiment" value rather than "specimen" value.
% These for demo only since we are not using them to help generate the IPVs.
expDataSetIndex = invDB.addExpDataSet(specimenNum, experimentNum, ...
                    ABISamplingRate, ...
                    stimulusType, expInfo.stimCurrent, ...
                    specData.ri, specData.tau, ...
                    expData.frstSpkThresholdV, ...
                    specData.v_rest, specData.peak_v_long_square);

%% Get the data set for access directly from the database if desired
expDataSet = invDB.getExpDataSet(specimenNum, experimentNum);

%% Define input parameters and other settings
% Set constant input parameters
delay = 1020.0;     % To match ABI Long Square stimulus
vinit = -65.0;      % mV
stimdur = 1000.0;   % To match ABI Long Square
tstep = 1/SimSamplingRate*1000; % in msec
tstop = 3000.0;                 % in msec  
% rcdintvl is not used via changes to PySim.py in this dir,
% to ensure a proper timebase for the ABI feature extraction code
rcdintvl = tstep; % not used
Kh_soma     = 0.0005;
Kh_smooth   = 0.00;
Kh_spiny    = 0.00;
CaE_soma    = 0.00;
KD_soma     = 0.00;
p17 = NaN; p18 = NaN; p19 = NaN; p20 = NaN; p21 = NaN;

% Define simulation-variable input parameters
% current in nA
% curr = {2.00};
curr = {0.50, 1.00, 1.50, 2.00, 2.50, 3.00};

% CaE_smooth  = {0.008};
CaE_smooth  = {0.000, 0.008};
CaE_spiny   = {0.00456};
% CaE_spiny   = {0.000, 0.008};

%KD_smooth   = {0.000};
KD_smooth   = {0.00, 0.09};
KD_spiny    = {0.09};
% KD_spiny    = {0.00, 0.09};

%% Set up the metaheuristic for parameter search
metaheurInitData{1,1} = curr;
metaheurInitData{2,1} = CaE_smooth;
metaheurInitData{3,1} = CaE_spiny;
metaheurInitData{4,1} = KD_smooth;
metaheurInitData{5,1} = KD_spiny;
% explicitGrid will do the Cartesian product of the cell arrays
mh = explicitGrid(metaheurInitData);
nm.log.write(['Using metaheuristic ' mh.getName() '.']);

%% Set up the compare class (objective function class)
% Derived from the Comparator class
cmp = CmpMM(abiDBConn, invDB, nmDirectorySet.localCellTypesDir, ...
            nmDirectorySet.curlDir);  
nm.log.write(['Using comparison algorithm ' cmp.getName() '.']);

%% Run parameter search starting with generation zero
nm.log.write(['Starting metaheuristic ' mh.getName() '.']);
points = mh.getPointSet() %#ok<NOPTS>
comparisonResults = {};
while ~isempty(points)
    generation = mh.getGenerationNumber();
    simSetID = ['Spec_' num2str(specimenNum) ...
                '_Sweep_' num2str(experimentNum) ...
                '_Gen_' num2str(generation)];
    simSetFileName = [simSetID '.txt'];
    simulationRoot = 'Point';
    %% Start a SimSpec file which holds the ipvs of the SimSet for running
    mmss = MMInvDBSimSpecFile(nm.getSimSpecFileDir(), simSetID, simSetFileName);
    % Add the SimSpec file header
    mmss.InsertHeader();

    for j = 1:size(points,1)
        % Do all preparation for each point
        simID = [simulationRoot num2str(j, '%04u')];
        inParam = {points{j,1}, ... % curr(ent)
                   vinit, delay, stimdur, ...
                   tstep, tstop,  rcdintvl, ...
                   Kh_soma, Kh_smooth, Kh_spiny, ...
                   CaE_soma, ...
                   points{j,2}, ... % CaE_smooth
                   points{j,3}, ... % CaE_spiny
                   KD_soma, ...
                   points{j,4}, ... % KD_smooth
                   points{j,5}, ... % KD_spiny
                   p17, p18, p19, p20, p21};
        % Add the corresponding SimSpec line to the SimSpec file
        mmss.addPoint(false, simID, inParam{:})        
        
        %% Add the corresponding ipv to the database
        ipvIndex = invDB.addIPV(expDataSetIndex, inParam{:});
                            
        %% Add the corresponding simulation run into the database;
        % some items will be updated after simulation results downloaded 
        runIndex = invDB.addSimulationRun(ipvIndex, ...
                                nm.getSessionIndex(), simSetID, ...
                                simID, SimSamplingRate, tstop);
        % simList holds each point's uniqueness information for use later
        % in comparisons
        simList{j,1}.sessionID = nm.getSessionID();    %#ok<*SAGROW>
        simList{j,1}.simSetID = simSetID;
        simList{j,1}.simID = simID;
    end
    
    %% Run the simSet for this generation 
    result = nm.runFromFile(simSetFileName);

    %% For the simSet results, do comparisons with experimental data 
    % and log them into the database.
    % Logging comparison type allows using multiple types of 
    % comparisons here with separate entries into database
    comparisonResults = [comparisonResults ...
        cmp.compare({num2str(specimenNum)}, ...
                    {num2str(experimentNum)}, simList)]; %#ok<AGROW>
    
    %% Get the next generation of points to investigate
    points = mh.getPointSet();
end
nm.log.write(['Termination criteria reached.  Terminating search.']);


%% Run post-metaheuristic analysis
% Get the comparisons for this session, find the minimum for each score
% and which run they are associated with.
comps = invDB.getSessionComparisons(nm.getSessionID());

%% score1
minScore = realmax;
minRunIDX = intmax;
for j = 1:length(comps.runIDX)
     if comps.score1(j) < minScore
         minScore = comps.score1(j);
         minRunIDX = comps.runIDX(j);
     end
end
% Find the ipv corresponding to that run and print the results message
ipvData = invDB.getIPVFromRunIDX(minRunIDX);
runData = invDB.getSimulationRunFromRunIDX(minRunIDX);
simID = runData.simID{1};
msg = ['Score1: Minimum is run "' simID ...
       '" with score1=' num2str(minScore)];
nm.log.write(msg);

%% score2
if cmp.getNumScoresUsed() > 1
    minScore = realmax;
    minRunIDX = intmax;
    for j = 1:length(comps.runIDX)
         if comps.score2(j) < minScore
             minScore = comps.score2(j);
             minRunIDX = comps.runIDX(j);
         end
    end
    % Find the ipv corresponding to that run and print the results message
    ipvData = invDB.getIPVFromRunIDX(minRunIDX);
    runData = invDB.getSimulationRunFromRunIDX(minRunIDX);
    simID = runData.simID{1};
    msg = ['Score2: Minimum is run "' simID ...
           '" with score2=' num2str(minScore)];
    log.write(msg);
end

%% score3
if cmp.getNumScoresUsed() > 2
    minScore = realmax;
    minRunIDX = intmax;
    for j = 1:length(comps.runIDX)
         if comps.score3(j) < minScore
             minScore = comps.score3(j);
             minRunIDX = comps.runIDX(j);
         end
    end
    % Find the ipv corresponding to that run and print the results message
    ipvData = invDB.getIPVFromRunIDX(minRunIDX);
    runData = invDB.getSimulationRunFromRunIDX(minRunIDX);
    simID = runData.simID{1};
    msg = ['Score3: Minimum is run "' simID ...
           '" with score3=' num2str(minScore)];
    log.write(msg);
end

%% Close up
close(abiDBConn);
databaseSaveName = ['_BU_' nm.getSessionID()];
invDB.save(userData.mysqlUsername, investigationDir, databaseSaveName);
msg = ['Investigation database ' invDB.getDatabaseName() ' saved as ' ...
       databaseSaveName ' in directory ' investigationDir];
log.write(msg);
invDB.delete();
disp('Script complete.');
