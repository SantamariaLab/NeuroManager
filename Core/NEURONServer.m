% NEURONServer
% Synapse has no constraints on wallclocktime.
classdef NEURONServer < StandaloneServer & NeuronMachine
    methods
        function obj = NEURONServer(~,...
                            hostID, hostOS, ~, baseDir, scratchDir, ...
                            simFileSourceDir, custFileSourceDir,... 
                            modelFileSourceDir,... 
                            simType, numSims,...
                            auth, log, notificationSet, dataFunc, ~, ~, ~)
            md = dataFunc();
            obj = obj@NeuronMachine(md);
            obj = obj@StandaloneServer(md, hostID, hostOS, baseDir,...
                                    scratchDir, ...
                                    simFileSourceDir, custFileSourceDir,... 
                                    modelFileSourceDir,... 
                                    simType, numSims,...
                                    0, '', ...
                                    auth, log, notificationSet);
        end
        
        % ----------
        % Neuron model processing is machine-dependent
        % Refer to NeuroManagerStagin'g.xlsx
        % Since Synapse has no distinction between P and D stages
        % we pick the D stage arbitrarily to do mod file compilation
        function str = getCompileNeuronModelFilesStrPhaseP(obj, simulation) %#ok<INUSD>
            str = '';  
        end

        % ----------
        % Neuron model processing is machine-dependent
        % Refer to NeuroManagerStaging.xlsx
        % Since Synapse has no distinction between P and D stages
        % we pick the D stage arbitrarily to do mod file compilation
        function str = getCompileNeuronModelFilesStrPhaseD(obj, simulation) 
            str = obj.getModelFileCompileStr(simulation);
        end
    end
    
    %     methods (Access=protected)        
%     % createDownloadExpectFile.m
%     % Can be overridden here for localization.
% %     function createDownloadExpectFile(obj, hostdir, targetpath)
% %         ...
% %     end
%     end

end
