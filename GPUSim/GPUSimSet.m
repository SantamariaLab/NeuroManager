% GPUSimSet.m
% Runs example MATLAB GPU simulations on the GPU.

clear; clear classes; clear java

myData = '';
[nmAuthData, nmDirectorySet, userData] = loadUserStaticData(myData);
nmDirectorySet.customDir = fullfile(nmDirectorySet.nmMainDir, 'GPUSim');
nmDirectorySet.simSpecFileDir = nmDirectorySet.customDir;
nmDirectorySet.resultsDir = nmDirectorySet.customDir;

nm = NeuroManager(nmDirectorySet, nmAuthData, userData,...
            'notificationsType', 'NONE',...
            'pollDelay', 15,...
            'logEchoFlag', true, ...
            'useDualKey', true);

% Create a machine set configuration
% Note: NeuroManager currently has no provision for labelling machines as
% having GPU or not.  It's up to the user here to ensure that the proper
% machines are chosen. Errors of this type may have unhelpful error messages. 
config = MachineSetConfig(nm.isSingleMachine());
% Our Server02 has a GPU on it
config.addMachine(MachineType.MYSERVER02,      1, '/home/username/WorkDirOnMYSERVER02');
config.addMachine(MachineType.STAMPEDEGPUDEV,  0, '/work/xxxxx/username/WorkDirOnStampede_GPUDEV',...
                                                  'WallClockTime', '00:30:00');
config.addMachine(MachineType.STAMPEDEGPU,     0, '/work/xxxxx/username/WorkDirOnStampede_GPU',...
                                                  'WallClockTime', '00:30:00');

nm.testCommunications(config);

nm.constructMachineSet(SimType.SIM_GPUSIM, config);

result = nm.runFromFile('GPUSimSpec.txt');

nm.removeMachineSet();

nm.shutdown();
