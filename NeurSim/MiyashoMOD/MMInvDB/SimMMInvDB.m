% SimMMInvDB
% Defines the class for doing Neuron Simulations with the Miyasho2001
% model. Must be used with compatible UserSimulation.m.
%
% See Miyasho, T.; Takagi, H.; Suzuki, H.; Watanabe, S.; Inoue, M.;
% Kudo, Y. & Miyakawa, H. Low-threshold potassium channels and a
% low-threshold calcium channel regulate Ca2+ spike firing in the dendrites
% of cerebellar Purkinje neurons: a modeling study. Brain Res, Department
% of Physics, School of Science and Engineering, Waseda University,
% Shinjyuku-ku, 169, Tokyo, Japan., 2001, 891, 106-115.
%
% This class adds the soma, smooth, and spiny conductances for CaE, KD,
% and Kh ion channels to the variable input parameters available to the
% user.  It also makes use of the investigation database to store each run
% and its associated feature extractions.
classdef SimMMInvDB < SimNeurPurkinjeMiyasho2001
    properties(Access=private)
        addlCustomFileList = {'__init__.py', ...
                              'ephys_extractor.py', ...
                              'ephys_features.py', ...
                              'extract_cell_features.py', ...
                              'feature_extractor.py', ...
                              'extractABIExpFeatures.m', ...
                              'STGFeatExtr.py' ...
                              }; 
        hocFileList = {};  % added to dynamically
    end
    properties
    end
    
    methods
        function obj = SimMMInvDB(id, machine, ... 
                                        type, dbH, log, notificationSet)
            obj = obj@SimNeurPurkinjeMiyasho2001(id, machine, ...
                                        type, dbH, log, notificationSet);
            obj.version = '1.0';  % Will be recorded in log
        end
        
        % ---
        function list = getAddlCustomFileList(obj)
            list = getAddlCustomFileList@SimNeurPurkinjeMiyasho2001(obj);
            list = [list obj.addlCustomFileList];
        end
        
        % ---
        function preRunModelProcPhaseHHocFileModification(obj, simulation)   
        % Create and/or modify simulation-dependent hoc files in the
        % Machine Scratch directory, add them to the hoc file list, then
        % ship them to the simulation model directory. 
        % Abstract is in Sim_Neuron.
            % Here we "create" our biomech.hoc on the fly by taking the
            % biomech file, from which Kh/KD/CaE entries have been removed, and
            % appending the appropriate lines to insert the Kh conductances
            % We need a unique name though since the scratch directory is
            % on the host and common to all machines
            sourceBiomechFilename = 'purkinje_NONMORPH_noKh_noKD_noCaE.hoc';
            sourceBiomechFile = fullfile(obj.machine.getCustFileSourceDir(),...
                                         sourceBiomechFilename);
            scratchBiomechFile = fullfile(obj.machine.getScratchDir(),...
                           [simulation.getID() '_' sourceBiomechFilename]);
            copyfile(sourceBiomechFile, scratchBiomechFile);
            f = fopen(scratchBiomechFile, 'a');
            fprintf(f, '%s\n',...   
                ['/* The following lines added by the ' ...
                 'PreRunModelProcPhaseHHocFileModification method']);
            fprintf(f, '%s\n',   ['    of the SimMMInvDB class. */']);
            fprintf(f, '%s\n',   ['soma {']);
            fprintf(f, '%s\n',   ['     insert Kh   gkbar_Kh = '...
                                  simulation.getParam(8)]);
            fprintf(f, '%s\n',   ['     insert CaE  cai = 4e-5 cao = 2.4  gcabar_CaE = '...
                                  simulation.getParam(11)]);
            fprintf(f, '%s\n',   ['     insert KD   gkbar_KD = '...
                                  simulation.getParam(14)]);
            fprintf(f, '%s\n\n', ['     }']);
            
            fprintf(f, '%s\n',   ['for i=0,84 SmoothDendrite[i]  {']);
            fprintf(f, '%s\n',   ['     insert Kh   gkbar_Kh = '...
                                  simulation.getParam(9)]);
            fprintf(f, '%s\n',   ['     insert CaE  cai = 4e-5 cao = 2.4  gcabar_CaE = '...
                                  simulation.getParam(12)]);
            fprintf(f, '%s\n',   ['     insert KD   gkbar_KD = '...
                                  simulation.getParam(15)]);
            fprintf(f, '%s\n\n', ['     }']);
            
            fprintf(f, '%s\n',   ['for i=0,1001 SpinyDendrite[i]  {']);
            fprintf(f, '%s\n',   ['     insert Kh   gkbar_Kh = '...
                                  simulation.getParam(10)]);
            fprintf(f, '%s\n',   ['     insert CaE  cai = 4e-5 cao = 2.4  gcabar_CaE = '...
                                  simulation.getParam(13)]);
            fprintf(f, '%s\n',   ['     insert KD   gkbar_KD = '...
                                  simulation.getParam(16)]);
            fprintf(f, '%s\n\n', ['     }']);
            fclose(f);
            % Upload the file since it was taken off the original list
            % Note that, for debugging/verification, we can look at the
            % biomech file in the machine scratch dir on the host, or look
            % at the targetbiomechfilename on the target, or at the
            % downloaded concatenated file in the output dir on the target,
            % or at the unzipped file after post-simulation downloaded.
            targetBiomechFilename = [simulation.getID(), '_Biomech.hoc'];
            obj.machine.fileToMachine(scratchBiomechFile,...
                fullfile(simulation.getTargetModelDir, targetBiomechFilename));
            % Add to the hoc file list for proper target file manipulation
            obj.hocFileList = [obj.hocFileList, targetBiomechFilename];
        end
        
        function postDownloadProcessingSimulatorSpecific(obj, simulation) 
            % Update the simulation run in the database
            if obj.dbH~=0
                obj.log.write(['Investigation database: ' ...
                               'Updating simulation runtime ' ...
                               'for simulation ' simulation.getID()]);

                % get the unique run index 
                runIDX = obj.dbH.getSimulationRunIndex(simulation.getID(), ...
                    simulation.getSimSetID(), simulation.getSessionID());

                % update the run in the investigation database
                simulatorIDX = obj.simulatorIndex;  % Not sure about this approach
                resultsDir = simulation.getHostBaseDir();
                stimulusFilename = 'stimulusdata.txt';
                voltageFilename = 'voltagedata.txt';
                spikeMarkerFilename = 'NULL';
                timeFilename = 'timedata.txt';
                fxFilename = 'ABIFeatures.json';
                simTime   = simulation.getExecutionTime();
                simResult = simulation.getResult();
                if strcmp(simResult, 'COMPLETE')
                    simResult = 'Success';
                else
                    simResult = 'Failure';
                end
                obj.dbH.updateSimulationRun(runIDX, simulatorIDX, ...
                            resultsDir, stimulusFilename, voltageFilename, ...
                            spikeMarkerFilename, timeFilename, fxFilename, ...
                            simTime, simResult);

                % Add the feature extraction to the database
                obj.log.write(['Adding feature extraction data to database ' ...
                               'for simulation ' simulation.getID() '.']);
                resultsDir = simulation.getHostBaseDir();
                featuresFilename = 'ABIFeatures.json';
                featuresPath = fullfile(resultsDir, featuresFilename);
                if exist(featuresPath, 'file')==2
                    featDat = loadjson(featuresPath);
                    % Remove elements that are not supported by the table
                    if isfield(featDat, 'spikeData')
                        featDat = rmfield(featDat, 'spikeData');
                    end
                    if isfield(featDat, 'simID')
                        featDat = rmfield(featDat, 'simID');
                    end
                else
                    featDat = struct('hasBursts', 0, ...
                                     'maxBurstiness','NULL', ... 
                                     'hasPauses', 0, ...
                                     'adaptation','NULL', ... 
                                     'threshold','NULL', ... 
                                     'latency','NULL', ...  
                                     'isi_cv','NULL', ... 
                                     'stimulusLatency','NULL', ... 
                                     'delayRatio','NULL', ... 
                                     'first_isi','NULL', ... 
                                     'numPauses','NULL', ... 
                                     'avgFiringRate','NULL', ... 
                                     'numSpikes', 0, ...
                                     'numBursts', 0, ...
                                     'f_peak','NULL', ... 
                                     'analysisDuration', 000.0, ...
                                     'analysisStart', 1020.0, ...
                                     'mean_isi','NULL', ... 
                                     'hasSpikes', 0, ... 
                                     'pauseFraction','NULL', ... 
                                     'delayTau','NULL');
                end
                obj.dbH.addSimFeatureExtraction(featDat, runIDX);
                obj.log.write(['Feature extraction data added to ' ...
                               'investigation database ' ...
                               'for simulation ' simulation.getID() '.']);
            end
        end
        
    end
end
