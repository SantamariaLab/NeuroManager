% Visualize comparison wrt the experimental data
function visComparison(obj, cmpIDX, highlightSpikeInsertion)

    % Hardwired locations
	expDataDir = ['C:\Users\David\Dropbox\Documents\SantamariaLab\Projects\Fractional\ABI-FLIF\Cache\cell_types'];
	abiSamplingRate = 200000;
    cURLBinDir = ['C:/Users/David/Dropbox/Documents/SantamariaLab/Projects/' ... 
                  'ProjNeuroMan/CloudStuff/curl-7.46.0-win64-mingw/bin/'];
                                     
    % Get the simulation in question
    simRunData = obj.simDB.getSimulationRunDataFromCmpIDX(cmpIDX);
    runIDX      = simRunData.runIDX;
    simID       = simRunData.simID{1};
    simSetID    = simRunData.simSetID{1};
    simSampleRate = simRunData.simSampleRate;
    rd          = simRunData.resultsDir{1};
    vfn         = simRunData.voltageFilename{1};
    smfn        = simRunData.spikeMarkerFilename{1};
    sfn         = simRunData.stimulusFilename{1};
    
    % Get the experimental data in question
    expDataSet = obj.simDB.getExpDataSetFromRunIDX(runIDX);
    specID = expDataSet.expSpecimenID;
    expID = expDataSet.expExperimentID;
    
    nwbFilePath = ...
        fullfile(expDataDir, ['specimen_' num2str(specID)], 'ephys.nwb');
    acd = ABICellData(nwbFilePath, cURLBinDir);
    exp = acd.GetExperiment(expID);
    sweep = exp.GetExperimentSweep();
    expStimData = sweep.GetStimulusData();
    expAcqData = sweep.GetAcquisitionData();
    expTimeBase = sweep.GetTimeBase(false);
    threeSecNdx = abiSamplingRate*3 + 1;
    
    % Plot the experimental part
    figure
    subplot(2,1,1)
    plot(expTimeBase(1:threeSecNdx), expAcqData(1:threeSecNdx)*1000, '-k')
    hold on
    plot(expTimeBase(1:threeSecNdx), expStimData(1:threeSecNdx)*10^11, '-g')
    title(['ABI Acquisition: Specimen ' num2str(specID) ... 
           '  Experiment ' num2str(expID)]);
%     xlabel('Time (sec)')
    xlim([0 3.0])
    ylabel('Voltage (mV)')
    grid on
    
    % Plot the simulated part
    simV = load(fullfile(rd, vfn), '-ascii');
    simSM = load(fullfile(rd, smfn), '-ascii');
    simS = load(fullfile(rd, sfn), '-ascii');
    subplot(2,1,2)
    simTimeBase = 1:length(simV);
    simTimeBase = simTimeBase/simSampleRate;
    plot(simTimeBase, simV, '-k')
    hold on
    if highlightSpikeInsertion
        spikeSM = (1./(simSM./simSM)) .* simV;
        refracSM = (1./(simSM > 1)) .* simV;
        plot(simTimeBase, spikeSM,  '-r', 'LineWidth', 1.5)
        plot(simTimeBase, refracSM, '-b', 'LineWidth', 1.5)
    end
    plot(simTimeBase, simS*10, '-g')
    title({'ABI-FLIF Simulation', ...
           ['simSetID: ' simSetID '   simID: ' simID]}, ...
           'Interpreter', 'None')
    xlabel('Time (sec)')
    ylabel('Voltage (mV)')
    xlim([0 3.0])
    grid on
    
end