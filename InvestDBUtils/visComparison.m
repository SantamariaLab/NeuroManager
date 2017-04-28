% Visualize comparison wrt the experimental data
function visComparison(cmpIDX, highlightSpikeInsertion)

    % Hardwired locations
    addpath('C:\Users\David\Dropbox\Documents\SantamariaLab\Projects\ABAtlas\ABIApiML')
    simsDatabaseName = 'ShortTermDB';
    simsDBConn = database.ODBCConnection(simsDatabaseName, ...
                                         'david','Uni53mad'); %#ok<*NOPTS>
	expDataDir = ['C:\Users\David\Dropbox\Documents\SantamariaLab\' ...
                  'Projects\Fractional\ABI-FLIF\FeatExtractDev\cell_types'];
	abiSamplingRate = 200000;
                                     
    % Get the simulation in question
    q = ['SELECT simulationRuns.runIDX, ' ...
         'simulationRuns.simID, ' ...
         'simulationRuns.simSetID, ' ...
         'simulationRuns.simSampleRate, ' ...
         'simulationRuns.resultsDir, ' ...
         'simulationRuns.voltageFilename, ' ...
         'simulationRuns.spikeMarkerFilename, ' ...
         'simulationRuns.stimulusFilename FROM ' ...
         'comparisons INNER JOIN simulationRuns ' ...
         'ON comparisons.runIDX=simulationRuns.runIDX ' ...
         'WHERE comparisons.cmpIDX=' num2str(cmpIDX) ';'];
    setdbprefs('DataReturnFormat','structure');
    curs = exec(simsDBConn, q);
    curs = fetch(curs);
    temp = curs.Data;
    close(curs)
    runIDX = temp.runIDX;
    simID  = temp.simID{1};
    simSetID  = temp.simSetID{1};
    simSampleRate = temp.simSampleRate;
    rd     = temp.resultsDir{1};
    vfn    = temp.voltageFilename{1};
    smfn    = temp.spikeMarkerFilename{1};
    sfn    = temp.stimulusFilename{1};
    
    % Get the experimental data in question
    q = ['SELECT expDataSets.expSpecimenID, expDataSets.expExperimentID ' ...
         'FROM ((simulationRuns INNER JOIN ipvs' ...
         ' ON simulationRuns.ipvIDX=ipvs.ipvIDX)' ...
         ' INNER JOIN expDataSets ' ...
         'ON ipvs.expDataSetIDX=expDataSets.expDataSetIDX) ' ...
         'WHERE simulationRuns.runIDX=' num2str(runIDX) ';'];
    curs = exec(simsDBConn, q);
    curs = fetch(curs);
    temp = curs.Data;
    close(curs);
    specID = temp.expSpecimenID;
    expID = temp.expExperimentID;
    nwbFilePath = ...
        fullfile(expDataDir, ['specimen_' num2str(specID)], 'ephys.nwb');
    acd = ABICellData(nwbFilePath);
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
    title({'ABI-FLIF Simulation', ['simSetID: ' simSetID '   simID: ' simID]}, 'Interpreter', 'None')
    xlabel('Time (sec)')
    ylabel('Voltage (mV)')
    xlim([0 3.0])
    grid on
    
end