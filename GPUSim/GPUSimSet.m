% GPUSimSet.m
% Runs example MATLAB GPU simulations on the GPU.

clear; clear classes; clear java

[NMAuthData, NMDirectorySet, UserData] = myNMStaticData();
NMDirectorySet.CustomDir = fullfile(NMDirectorySet.NMMainDir, 'GPUSim');
NMDirectorySet.ResultsDir = NMDirectorySet.CustomDir;

nm = NeuroManager(NMDirectorySet, NMAuthData, UserData,...
            'NotificationsType', 'NONE',...
            'PollDelay', 15,...
            'LogEchoFlag', true, ...
            'UseDualKey', true);

% Create a machine set configuration
% Note: NeuroManager currently has no provision for labelling machines as
% having GPU or not.  It's up to the user here to ensure that the proper
% machines are chosen. Errors of this type may have unhelpful error messages. 
config = MachineSetConfig();
% Our Server02 has a GPU on it
config.AddMachine(MachineType.MYSERVER02,      1, '/home/username/WorkDirOnMYSERVER02');
config.AddMachine(MachineType.CBI_GPU,         0, '/home/username/WorkDirOnMYSGECLUS01_GPU');
config.AddMachine(MachineType.STAMPEDE_GPUDEV, 0, '/work/xxxxx/username/WorkDirOnStampede_GPUDEV',...
                                                  'WallClockTime', '00:30:00');
config.AddMachine(MachineType.STAMPEDE_GPU,    0, '/work/xxxxx/username/WorkDirOnStampede_GPU',...
                                                  'WallClockTime', '00:30:00');

nm.TestCommunications(config);

nm.ConstructMachineSet(SimType.SIM_GPUSIM, config);

result = nm.RunFromFile('GPUSimSpec.txt');

nm.RemoveMachineSet();

nm.Shutdown();
	