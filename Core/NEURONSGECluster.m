% NEURONSGECluster
% Ignores wall clock time
classdef NEURONSGECluster < SGECluster & NeuronMachine
    methods
        function obj = NEURONSGECluster(~,...
                                   hostID, hostOS, ~, baseDir, scratchDir,...
                                   simFileSourceDir, custFileSourceDir,...
                                   modelFileSourceDir,...
                                   simType, numSims,...
                                   auth, log, notificationSet, dataFunc,...
                                   queueData, parEnvStr, resourceStr)
            md = dataFunc();
            obj = obj@NeuronMachine(md);

            % Use cross-compilation on Dendrite (just to test the
            % cross-compilation code)
            useCrossCompilation = false;
            if useCrossCompilation
                xCompilationMachine =...
                            xCompileDendrite(hostID, hostOS,...
                                              'XCOMPILE', auth); %#ok<*UNRCH>
                mdx = createDendriteData();
                xCompilationScratchDir =...
                            mdx.getSetting('xCompDir');
            else
                xCompilationMachine = 0;
                xCompilationScratchDir = '';
            end
            obj = obj@SGECluster(md, queueData,...
                                   parEnvStr, resourceStr,...
                                   hostID, hostOS, baseDir, scratchDir, ...
                                   simFileSourceDir, custFileSourceDir,...
                                   modelFileSourceDir,...
                                   simType, numSims,...
                                   xCompilationMachine,...
                                   xCompilationScratchDir,...
                                   auth, log, notificationSet);
         end
        
        % ----------
        % Neuron model processing is machine-dependent. On CBI we compile
        % the model files as part of the job submission, not here.
        % This is called from SimNeuron.
        % Refer to NeuroManagerStaging.xlsx
        function str = getCompileNeuronModelFilesStrPhaseP(obj, simulation) %#ok<INUSD>
            str = '';  
        end
        
        % ----------
        % Neuron model processing is machine-dependent. On CBI we compile
        % the model files as part of the job submission, which is here.
        % This is called from SimNeuron.
        % Refer to NeuroManagerStaging.xlsx
        function str = getCompileNeuronModelFilesStrPhaseD(obj, simulation) 
            str = obj.getModelFileCompileStr(simulation);
        end
        
        % ----------
        % Override the job file here if you like
        %function jobfilename = PreRunCreateJobFile(obj, scratchdir, jobroot, remoterundir, runcommand)
            % ...
        %end
    end
    
    %     methods (Access=protected)        
%     % CreateDownloadExpectFile.m
%     % Can be overridden here for localization.
% %     function CreateDownloadExpectFile(obj, hostdir, targetpath)
% %         ...
% %     end
%     end

end
