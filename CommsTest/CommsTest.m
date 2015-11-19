% CommsTest.m
% Sets up a Virtual Machine and tests communications and file transfer

clc
disp('Clearing variables, classes, and java. Please wait...');
clear; clear variables; clear classes; clear java %#ok<*CLSCR>

% Part I: Set up static data
myData = '';  % Path to user's ini file
[nmAuthData, nmDirectorySet, userData] = loadUserStaticData(myData);

% Part II: Define NeuroManager Host directories specific to this script
nmDirectorySet.customDir = fullfile(nmDirectorySet.nmMainDir, 'CommsTest');
nmDirectorySet.simSpecFileDir = nmDirectorySet.customDir;
nmDirectorySet.resultsDir = nmDirectorySet.customDir;

% Part III: Create the NeuroManager object
nm = NeuroManager(nmDirectorySet, nmAuthData, userData,...
                 'notificationsType', 'NONE', 'useDualKey', true);
            
% Part IV: Create a machine set configuration
% Change the order here with experience to put the fastest machines
% first; balance that with the number of simulators per machine so that
% one machine isn't always full while the others are idle.
config = MachineSetConfig(nm.isSingleMachine());
config.addMachine(MachineType.MYSERVER02, 1, 'YourWorkDirectoryHere');

% Part V: Test Communications
nm.testCommunications(config);

% Part IX: Clean up and Shutdown
nm.shutdown();
