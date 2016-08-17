% ----------------
function constructMachineSet(obj, simType)
% Construct the set of machines and their simulators from a
% machinesetconfig.
    % Update the webpage
    obj.displayStatusWebPage('constructmachine');

    % One host scratch dir for all machines, so all files must be
    % uniquely named. 
    obj.log.write(['Constructing machine set.']);
    if obj.simNotificationSet.isEnabled()
        notificationSubject = ['Re: NeuroManager Notice'];
        obj.simNotificationSet.send(notificationSubject,...
         ['Constructing machine set.'], '');
    end
    configStr = obj.machineSetConfig.printToStr;
    obj.log.write(configStr);

    obj.machineSetType = simType;

    % Perform the MATLAB Compilation
    % MLCM = MATLAB Compile Machine
    % Ignore compiler compatibility for now
    % Ignore test for compilation directory for now
    [config, workDir] = obj.mLCompileConfig.getMachine();
    MLCM = MATLABCompileMachine(config, obj.machineSetType, ...
                obj.machineScratchDir, workDir, ...
                obj.hostMachineData.id, obj.hostMachineData.osType, ...
                obj.auth, obj.log, obj.simNotificationSet);
    obj.MLCFTL = MLCM.getCompilationFileTransferList();
    MLCM.gatherFiles(obj.simCoreDir, obj.customSimDir);
%     disp('Stopped after moving files into machineScratch\ML2Compile')
%     pause
    MLCM.upload4Compile();
%     disp('Stopped after moving files up to remote')
%     pause
    
    MLCM.preCompile();
%     disp('Stopped after preCompile')
%     pause
    checkfilePathlist = MLCM.compile();
%     disp('Stopped after compile')
%     pause
    disp('Waiting for compile')
    while(1)
        result = MLCM.checkForCheckfileList(checkfilePathlist)
        if result(1) 
            break
        elseif result(2)
            error('MATLAB Compilation Failure')
        else
            pause(10);
        end
    end
    disp('Compile complete')
%     pause
    MLCM.postCompile();
    disp('Stopped after postCompile')
    pause

    
    % Make the machines in the MachineSetConfig
    obj.machineSet = obj.makeMyMachines(obj.machineScratchDir,...
                                        obj.machineSetType, ...
                                        obj.auth);
    obj.numMachines = length(obj.machineSet);

    % Sit here and poll the machines until they are all ready.
    % The test drives machine state progression.
    % This poll delay is hardwired at 10.0 seconds; the simulator
    % poll delay later in the Run() method is the one set by the
    % user (we don't want that used here because we want the
    % machine setup to happen asap).
     while ~obj.machineSetReady()
         pause(10);
     end
    obj.log.write(['Machine set ready.']);
    if obj.simNotificationSet.isEnabled()
        notificationSubject = ['Re: NeuroManager Notice'];
        obj.simNotificationSet.send(notificationSubject,...
         ['Machine set ready.'], '');
    end

end
        