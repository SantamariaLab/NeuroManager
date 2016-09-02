% SimNeurPurkinjeMiyasho2001
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
classdef SimNeurPurkinjeMiyasho2001 < SimNeuron
    properties(Access=private)
        addlCustomFileList = {'PySim.py'};

        % The list of published mod files 
        modFileList = {'CaEdbs.mod', 'CalciumP.mod', 'CaP.mod',...
                       'CaP2.mod', 'CaT.mod', 'K2.mod',...
                       'K22.mod', 'K23.mod', 'KA.mod',...
                       'KC.mod', 'KC2.mod', 'KC3.mod',...
                       'KD.mod', 'Kdr.mod', 'Kh.mod',...
                       'Khh.mod', 'KM.mod', 'Leak.mod',...
                       'NaF.mod', 'NaP.mod'};
        hocFileList = {'purkinje_MORPH.hoc'};
    end
    properties
        version;
    end
    
    methods
        function obj = SimNeurPurkinjeMiyasho2001(id, machine,...
                                                  log, notificationSet)
            obj = obj@SimNeuron(id, machine, log, notificationSet);
            obj.version = '1.0';  % Will be recorded in log
        end
        
        % ---
        function list = getAddlCustomFileList(obj)
            list = getAddlCustomFileList@Simulator(obj);
            list = [list obj.addlCustomFileList];
        end

        % ---
        function list = getHocFileList(obj)
            list = getHocFileList@SimNeuron(obj);
            list = [list obj.hocFileList];
        end
        
        % ---
        function list = getModFileList(obj)
            list = getModFileList@SimNeuron(obj);
            list = [list obj.modFileList];
        end
        
        % ---
        function list = getModelFileList(obj)
            list = getModelFileList@ModelFileSim(obj);
            list = [list obj.modFileList obj.hocFileList];
        end

        % ---
        function preRunModelProcPhaseHModFileModification(obj, simulation)  %#ok<INUSD>
        % Create and/or modify simulation-dependent model files in the
        % Machine Scratch directory, then ship them to the simulation input
        % directory. Abstract is in Sim_Neuron.
            % Nothing to do for this class
        end

        % ---
        function preRunModelProcPhaseHHocFileModification(obj, simulation)   
        % Create and/or modify simulation-dependent hoc files in the
        % Machine Scratch directory, add them to the hoc file list, then
        % ship them to the simulation input directory. 
        % Abstract is in Sim_Neuron.
            % Here we "create" our biomech.hoc on the fly (well, not really
            % in this class - here we have already created it as
            % 'purkinje_NONMORPH.hoc' in a different directory and are just
            % shipping it up with a different name).  
            hostBiomechFilename = 'purkinje_NONMORPH.hoc';
            targetBiomechFilename = [simulation.getID(), '_Biomech.hoc'];
            bioMechFile = fullfile(obj.machine.getModelFileSourceDir(),...
                                     hostBiomechFilename);
            % Upload the file 
            obj.machine.fileToMachine(bioMechFile,...
                fullfile(simulation.getTargetInputDir, targetBiomechFilename));
            % Add to the hoc file list since it was not on the original list
            obj.hocFileList = [obj.hocFileList, targetBiomechFilename];
        end
    end
end
