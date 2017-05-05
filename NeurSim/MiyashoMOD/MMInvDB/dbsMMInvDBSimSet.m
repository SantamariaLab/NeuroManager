%% Initial prep
clc
disp('Clearing variables, classes, and java. Please wait...');
clear; clear variables; clear classes; clear java  

%%%
% voltages in mV; currents in pA; resistances in MOhms; times in msec
% rates in events/second
%%%

%% Set up a Neuromanager session
disp(['Starting the MMInvDB investigation']);

launchDir = ['C:\Users\David\Dropbox\Documents\SantamariaLab\Projects\' ... 
             'ProjNeuroMan\NeuroManager\NeurSim\MiyashoMOD\MMInvDB'];
investigationDir = fullfile(launchDir, 'MMInvDBInvestigation01');

% Possible hack - review this
abiUtilsDir = ['C:\Users\David\Dropbox\Documents\SantamariaLab\Projects\' ...
               'ProjNeuroMan\NeuroManager\ABIUtils'];
addlCustomFileList = {'__init__.py', ...
                      'ephys_extractor.py', ...
                      'ephys_features.py', ...
                      'extract_cell_features.py', ...
                      'feature_extractor.py', ...
                      'extractABIExpFeatures.m', ...
                      'STGFeatExtr.py' ...
                      };  
 for i=1:length(addlCustomFileList)
    sourceFile = fullfile(abiUtilsDir, addlCustomFileList{i});
	copyfile(sourceFile, launchDir);
 end
 
 % Set up NeuroManager with the MMInvDB simulator
myData = ['C:\Users\David\Dropbox\Documents'...
          '\SantamariaLab\Projects\ProjNeuroMan\NeuroManager' ...
          '\dbsStaticData.ini'];   
[nmAuthData, nmDirectorySet, userData] = loadUserStaticData(myData);
nmDirectorySet.customDir = launchDir;
% fullfile(nmDirectorySet.nmMainDir,...
%                                     'NeurSim', 'MiyashoMOD');
nmDirectorySet.modelDir = fullfile(nmDirectorySet.nmMainDir,...
                                    'NeurSim', 'MiyashoMOD');
nmDirectorySet.resultsDir = investigationDir;
nmDirectorySet.simSpecFileDir = nmDirectorySet.resultsDir;

nm = NeuroManager(nmDirectorySet, nmAuthData, userData,...
                  'maxNumSimSpecParams', 21,...
                  'notificationsType', 'NONE', 'useDualKey', true,...
                  'isSingleMachine', false);

log = nm.getLog(); % For log additions from this script

disp 'AFter NM construction'
% path

%% Connect with the experimental data (ABI) database
abiDatabaseName = 'ABICellSurvey';
log.write(['Connecting to abi database ' abiDatabaseName '.']);
abiDBConn = database.ODBCConnection(abiDatabaseName,'david','Uni53mad');

%% Attach the investigation database
% Connect with the simulations database
% Set up using the database toolbox database explorer app
% Show MATLAB where the inv database class is located
% For the ABI investigation database, metaheuristic, and comparator classes
addpath(['C:/Users/David/Dropbox/Documents/SantamariaLab/Projects/' ...
         'ProjNeuroMan/NeuroManager/InvestUtils']); 
addpath(abiUtilsDir)
addpath(nmDirectorySet.modelDir)
simsDataSourceName = 'MMInvDB';
simsDatabaseName = 'mminvdb';
log.write(['Connecting to investigation database ' simsDatabaseName ...
           ' using data source ' simsDataSourceName '.']);
invDB = abiMMCompDB(simsDataSourceName, simsDatabaseName, ...
                  'david', 'Uni53mad');

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

%% Move the SimSpecDir to the SimResults dir
d = nm.getSimResultsDir();
nm.setSimSpecFileDir(d);
nm.log.write(['SimSpec Directory changed to: ' nm.getSimSpecFileDir()]);
% SessionIndex was set by the attach function
invDB.updateSessionSimSpecDir(nm.getSessionIndex(), d);

%% Set simulator type and machine configuration
simulatorType = SimType.SIM_MMINVDB;
nm.setSimulatorType(simulatorType);
% MLCompileMachineInfoFile = 'SynapseInfo.json';
MLCompileMachineInfoFile = 'CheetahInfo.json';
nm.setMLCompileServer(MLCompileMachineInfoFile);
nm.doMATLABCompilation();

% Synapse NEURON installation appears to be broken
% nm.addStandaloneServer('SynapseInfo.json', 2, '/home/David.Stockton/NMDev'); 
% nm.addStandaloneServer('DendriteInfo.json', 8, '/home/David.Stockton/SMDev'); 
numSimulators = 6;
nm.addClusterQueue('CheetahInfo.json', 'General', ...
                   numSimulators, '/home/david.stockton/SMDev/ALL');
nm.printConfig();

%% Test communications, file transfers, and other compatibilities
if ~nm.verifyConfig()
    return;
end

%% Build the Simulators on the server
nm.constructMachineSet();

%% Select specimens and experiments
% specimens currently in the Cell Survey Database
specimens = [ ...
            484635029, ... % 01
            469801569, ... % 02
            469753383, ... % 03
            487667205, ... % 04
            468120757, ... % 05
            476104386, ... % 06
            484742372, ... % 07
            475622793, ... % 08
            464188580, ... % 09
            478058328, ... % 10
            476218657, ... % 11
            318808427, ... % 12
            479704527, ... % 13
            324493977, ... % 14
            483020137, ... % 15
            464212183, ... % 16
            476457450, ... % 17
            324266189, ... % 18
            478107198, ... % 19
            476686112, ... % 20
            478396248, ... % 21
            485058595, ... % 22
            475622680, ... % 23
            327962063, ... % 24
            474267418, ... % 25
            466664172, ... % 26
            474626527, ... % 27
            464198958  ... % 28
            ];

specExps = [];
specExps(1,1) = specimens(03); % 
specExps(1,2) =  51;           % (hero sweep for 469753383)
specimenNum = specExps(1,1);
experimentNum = specExps(1,2);

%% Grab the experimental features for those choices...
% (Not currently being used)
% addpath for the ABIFeatExtrData class
addpath(['C:/Users/David/Dropbox/Documents/SantamariaLab' ...
         '/Projects/Fractional/ABI-FLIF/ABICellSurvey/src']);
fxData = ABIFeatExtrData(abiDBConn);

%% Move things around a little
ABISamplingRate = 200000;
SimSamplingRate = 20000;     % simulation samples per second


%% Install the experimental features into the investigation database
expData = fxData.getExpFXData(specimenNum, experimentNum);
specData = fxData.getSpecFXData(specimenNum);
expInfo = fxData.getExpInfo(specimenNum, experimentNum);
% ...and put them into the simulations database as a new expDataSet;
% the expPx values will be used to generate the parameter space
stimulusType = expInfo.stimulusType{1};
% threshold: The experiment value rather than specimen value
expDataSetIndex = invDB.addExpDataSet(specimenNum, experimentNum, ...
                    ABISamplingRate, ...
                    stimulusType, expInfo.stimCurrent, ...
                    specData.ri, specData.tau, ...
                    expData.frstSpkThresholdV, ...
                    specData.v_rest, specData.peak_v_long_square);

%% Get the data set 
expDataSet = invDB.getExpDataSet(specimenNum, experimentNum);



%% Deal with input parameters and other settings

% Set constant input parameters
delay = 1020.0;
vinit = -65.0;
stimdur = 1000.0;  % To match ABI Long Square
tstep = 1/SimSamplingRate*1000; % in msec
tstop = 3000.0;                 % in msec  
rcdintvl = 0.1;
KD_soma     = 0.00;
Kh_soma     = 0.0005;
Kh_smooth   = 0.00;
Kh_spiny    = 0.00;
CaE_soma    = 0.00;
p17 = NaN;
p18 = NaN;
p19 = NaN;
p20 = NaN;
p21 = NaN;

% Define simulation-variable input parameters
curr = {0.40};
%curr = {-0.80, -0.40, 0.00, 0.40};

CaE_smooth  = {0.00123};
% CaE_smooth  = {0.000, 0.008};
CaE_spiny   = {0.00456};
% CaE_spiny   = {0.000, 0.008};

KD_smooth   = {0.078};
% KD_smooth   = {0.00, 0.09};
KD_spiny    = {0.090};
% KD_spiny    = {0.00, 0.09};

%% Set up the metaheuristic for parameter search
metaheurInitData{1,1} = curr;
metaheurInitData{2,1} = CaE_smooth;
metaheurInitData{3,1} = CaE_spiny;
metaheurInitData{4,1} = KD_smooth;
metaheurInitData{5,1} = KD_spiny;
mh = explicitGrid(metaheurInitData);

%% Set up the compare class (objective function class)
expDataDir = ['C:\Users\David\Dropbox\Documents\SantamariaLab\Projects\' ...
              'Fractional\ABI-FLIF\Cache\cell_types'];
% Cmp01 class compares hasSpikes, latency, and meanISI using L2 norm
% later put this type as input to metaheuristic?
%     cmp = Cmp01(abiDBConn, invDB, expDataDir, nmDirectorySet.curlDir);  
% Cmp02 class compares hasSpikes, latency, meanISI, adaptation, and
% numSpikes.
%	cmp = Cmp02(abiDBConn, invDB, expDataDir, nmDirectorySet.curlDir);  
cmp = CmpMM(abiDBConn, invDB, expDataDir, nmDirectorySet.curlDir);  
nm.log.write(['Using comparison algorithm ' cmp.getName() '.']);


%% Run parameter search starting with generation zero
nm.log.write(['Starting metaheuristic ' mh.getName() '.']);
points = mh.getPointSet() %#ok<NOPTS>
generation = 0;
comparisonResults = {};
while ~isempty(points)

    %% Start up a SimSpec file to hold the points 
    simSetID = ['Spec_' num2str(specimenNum) ...
                '_Sweep_' num2str(experimentNum) ...
                '_Gen_' num2str(generation)];

    % Create the SimSpec file header
    simSetFileName = [simSetID '.txt'];
    simulationRoot = 'Point';
%     mmss = MMInvDBSimSpecFile(investigationDir, simSetID, simSetFileName);
    mmss = MMInvDBSimSpecFile(nm.getSimSpecFileDir(), simSetID, simSetFileName);
    mmss.InsertHeader();

    %% Do all preparation for each point
    % simList holds each point's uniqueness information for use later
    % NOT CORRECT FOR MULTIPLE CELLS
%         simList{i,1} = struct;   %#ok<*SAGROW> 

    for j = 1:size(points,1)
        %% Add a SimSpec line to the SimSpec file
        simID = [simulationRoot num2str(j, '%04u')];
        simList{j,1}.sessionID = nm.getSessionID();    %#ok<*SAGROW>
        simList{j,1}.simSetID = simSetID;
        simList{j,1}.simID = simID;
        inParam = {points{j,1}, ... % curr
                   vinit, delay, stimdur, tstep, tstop,  rcdintvl, ...
                   Kh_soma, Kh_smooth, Kh_spiny, ...
                   CaE_soma, ...
                   points{j,2}, ... % CaE_smooth
                   points{j,3}, ... % CaE_spiny
                   KD_soma, ...
                   points{j,4}, ... % KD_smooth
                   points{j,5}, ... % KD_spiny
                   p17, p18, p19, p20, p21 ...
                   };
        mmss.addPoint(false, simID, inParam{:})        
        
        %% Add the corresponding ipv to the database
        ipvIndex = invDB.addIPV(expDataSetIndex, ...
                                points{j,1}, vinit, delay, stimdur, ...
                                tstep, tstop, rcdintvl, ...
                                Kh_soma, Kh_smooth, Kh_spiny, ...
                                CaE_soma, points{j,2}, points{j,3}, ...
                                KD_soma, points{j,4}, points{j,5}, ...
                                p17, p18, p19, p20, p21)
                            
        %% Add the corresponding simulation run into the database
        % update some items after simulation results downloaded 
        % usage of tstop and SimSamplingRate is NOT CONSISTENT
        % Will be updated at finish of simulation
        %runIndex = ...
        runIndex = invDB.addSimulationRun(ipvIndex, ...
                                nm.getSessionIndex(), simSetID, ...
                                simID, SimSamplingRate, tstop)
    end
    
    %% Run the simSet for this generation 
    result = nm.runFromFile(simSetFileName);

    %% For the simSet results, do comparisons with experimental data 
    % and log them into the database.
    % Logging comparison type allows using multiple types of 
    % comparisons here with separate entries into database
    comparisonResults = [comparisonResults ...
        cmp.compare({num2str(specimenNum)}, ...
                    {num2str(experimentNum)}, simList)] %#ok<AGROW>
    
    %% Get the next generation of points to investigate
    points = mh.getPointSet();
    generation = generation + 1;
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
runData = invDB.getRunDataFromRunIDX(minRunIDX);
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
    % Handle empty ipvData here...
    if ~isempty(fieldnames(ipvData))
        runData = invDB.getRunDataFromRunIDX(minRunIDX);
        simID = runData.simID{1};
        msg = ['Score2: Minimum is run "' simID ...
               '" with score2=' num2str(minScore)];
        log.write(msg);
    else
        % Not defined yet
    end
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
    runData = invDB.getRunDataFromRunIDX(minRunIDX);
    simID = runData.simID{1};
    msg = ['Score3: Minimum is run "' simID ...
           '" with score3=' num2str(minScore)];
    log.write(msg);
end

    
%% Close up
% close(abiDBConn);
% databaseSaveName = ['_BU_' nm.getSessionID()];
% invDB.save('david', investigationDir, databaseSaveName)
% msg = ['Investigation database ' invDB.getDatabaseName() ' saved as ' ...
%        databaseSaveName ' in directory ' investigationDir];
% log.write(msg);
% invDB.delete();
disp('Script complete.')
    
    
    
    
    
    
    
    
    
    
    
    
    
    
