% CollectGPUData prints the data from the MATLAB gpuDevice() object to the
% named file.
function collectGPUData(filepath)
    gpu = gpuDevice();
    f = fopen(filepath, 'w');
    fprintf(f, '%s: %s\n', '                  Name', gpu.Name);
    fprintf(f, '%s: %d\n', '                 Index', gpu.Index);
    % http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#compute-capabilities
    fprintf(f, '%s: %s\n', '     ComputeCapability', gpu.ComputeCapability);
    fprintf(f, '%s: %d\n', '        SupportsDouble', gpu.SupportsDouble);
    fprintf(f, '%s: %f\n', '         DriverVersion', gpu.DriverVersion);
    fprintf(f, '%s: %f\n', '        ToolkitVersion', gpu.ToolkitVersion);
    fprintf(f, '%s: %d\n', '    MaxThreadsPerBlock', gpu.MaxThreadsPerBlock);
    mtbs = gpu.MaxThreadBlockSize;
    fprintf(f, '%s: [%d] [%d] [%d]\n',...
                           '    MaxThreadBlockSize', mtbs(1), mtbs(2), mtbs(3));
    mgs = gpu.MaxGridSize;
    fprintf(f, '%s: [%d] [%d] [%d]\n', ...
                           '           MaxGridSize', mgs(1), mgs(2), mgs(3));
    fprintf(f, '%s: %d\n', '             SIMDWidth', gpu.SIMDWidth);
    fprintf(f, '%s: %e\n', '           TotalMemory', gpu.TotalMemory);
    fprintf(f, '%s: %e\n', '            FreeMemory', gpu.FreeMemory);
    
    % See
    % http://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#compute-capabilities
    % to determine number of cores per multiprocessor
    fprintf(f, '%s: %d\n', '   MultiprocessorCount', gpu.MultiprocessorCount);
    fprintf(f, '%s: %d\n', '          ClockRateKHz', gpu.ClockRateKHz);
    fprintf(f, '%s: %s\n', '           ComputeMode', gpu.ComputeMode);
    fprintf(f, '%s: %d\n', '  GPUOverlapsTransfers', gpu.GPUOverlapsTransfers);
    fprintf(f, '%s: %d\n', 'KernelExecutionTimeout', gpu.KernelExecutionTimeout);
    fprintf(f, '%s: %d\n', '      CanMapHostMemory', gpu.CanMapHostMemory);
    fprintf(f, '%s: %d\n', '       DeviceSupported', gpu.DeviceSupported);
    fprintf(f, '%s: %d\n', '        DeviceSelected', gpu.DeviceSelected);
    fclose(f);
