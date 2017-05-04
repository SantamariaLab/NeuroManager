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
% This class is somewhat arbitrary. We are not changing hoc or mod files
% simulation-by-simulation, so all we really need is one hoc file that is
% simulator-static. Our PySim.py file, however, is looking for a hoc file
% that is named simid + '.hoc', and (looking ahead) subclasses of this
% class will generate a simulation-specific biomechanisms file. So here we
% will use  PreRunModelProcPhaseHHocFileModification to create the biomech
% file and upload it. The morphology file will upload as part of simulator
% construction. The concatentation and rename will take place on the target
% in UserSimulation.  Then all our subclasses need to do is override the
% biomech construction.
classdef SimMMInvDB < SimNeurPurkinjeMiyasho2001
    properties(Access=private)
        % Need to add feature extraction (7) and stimulus (2) files
        addlCustomFileList = {'ABIStimulus.m',...
                              'LongSquare.m',...
                              '__init__.py', ...
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
        version;
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
            fprintf(f, '%s\n',...   
                ['    of the SimMMInvDB class. */']);
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
    end
end
