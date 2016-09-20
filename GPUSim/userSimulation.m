% userSimulation.m
% GPUSim.m version --- pairs with SimGPUSim class file.
% A trivial simulation simulation for designing and testing NeuroManager.
% Creates a two-frequency signal and plots it and its spectrum.
function [result, errMsg] =...
        userSimulation(machineID, runID, ~, ~, ~, outDir, varargin)
    % Convert the input parameter vector into familiar variable names
     inFreq1 = varargin{1};
     inAmp1 = varargin{2};
     inFreq2 = varargin{3};
     inAmp2  = varargin{4};
     frequency1 = str2double(inFreq1);
     amplitude1 = str2double(inAmp1);
     frequency2 = str2double(inFreq2);
     amplitude2 = str2double(inAmp2);

     duration = 3.0;
     samplingRate = 1000.0;
     if(isnan(frequency1) || isnan(amplitude1)  || isnan(frequency2)  || isnan(amplitude2))
         errMsg = 'Non-numerical input parameter from SimSpec';
         result = 1;
         return;
     end
    
    % Could also test frequency values here for less than Nyquist
    % (not implemented)
     
    % Check for a GPU; ignore multiple GPU case.
%     if  gpuDeviceCount == 0
%          errMsg = ['No GPU found on machine ' machineID '.'];
%          result = 1;
%          return;
%      end
    
    % Collect data on the GPU into file for download
  %  collectGPUData(fullfile(outDir, 'GPUData.txt'));

    % Create the signal
    t = 0:(1/samplingRate):duration;
    data = amplitude1 * sin(frequency1.*2.*pi.*t) + amplitude2 * sin(frequency2.*2.*pi.*t);
    len = length(t);
    NFFT = 2^nextpow2(len);
    
    % Repeat to accumulate time for speed comparisons
    for i=1:1000000  
%         dataGPU = gpuArray(data);               % --> transfer data from cpu mem to gpu mem
%         dataGPUFFT = fft(dataGPU,NFFT)/len;     % --> computes on gpu
%         dataCPUFFT = gather(dataGPUFFT);        % --> transfer the data back to cpu mem space
    end
    
    % Plot and save in the output directory
    h = figure;
    plot(t, data);
    title(['Voltage: ' runID ' on ' strrep(machineID, '_', ' ')]);
    xlabel('Time (sec)');
    ylabel('Amplitude (v)');
    try
        filename = ['voltage.fig'];
        saveas(h, fullfile(outDir, filename), 'fig')
    catch
        % Could return a specific error code here, but at the
        % moment it is not important.
        errMsg = ['Could not save figure' fullfile(outDir, filename)];
        result = 1;
        return;
    end
    try
        filename = ['voltage.tiff'];
        print('-dtiff','-r300', fullfile(outDir, filename));
    catch
        % Could return a specific error code here, but at the
        % moment it is not important.
        errMsg = ['Could not print figure' fullfile(outDir, filename)];
        result = 1;
        return;
    end
    
    h = figure;
    f = samplingRate/2*linspace(0,1,NFFT/2+1);
%     plot(f(1:NFFT/2), abs(dataCPUFFT(1:NFFT/2)+1));
    title(['fft: ' runID ' on ' strrep(machineID, '_', ' ')]);
    xlabel('Frequency (Hz)');
    ylabel('|Y(f)|');
    try
        filename = ['fft.fig'];
        saveas(h, fullfile(outDir, filename), 'fig')
    catch
        % Could return a specific error code here, but at the
        % moment it is not important.
        errMsg = ['Could not save figure' fullfile(outDir, filename)];
        result = 1;
        return;
    end
    try
        filename = ['fft.tiff'];
        print('-dtiff','-r300', fullfile(outDir, filename));
    catch
        % Could return a specific error code here, but at the
        % moment it is not important.
        errMsg = ['Could not print figure' fullfile(outDir, filename)];
        result = 1;
        return;
    end
    
%     save(fullfile(outDir, 'FFTdata.mat'), 'dataCPUFFT');
    
    result = 0; % Needs to return a status of 0 for success, 1 for failure
    errMsg = '';
end
