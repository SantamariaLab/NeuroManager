% verifyConfig.m
% Part of the NeuroManager class.
% Tests communications, file transfer, and other compatibilities with any
% machine in the config that has nonzero number of simulators. A true
% result means pass. 
% ---
function tfResult = verifyConfig(obj)
    testedMachines = {};
    obj.log.write(['Testing machine communications.']);
    if obj.simNotificationSet.isEnabled()
        notificationSubject = ['Re: NeuroManager Notice'];
        obj.simNotificationSet.send(notificationSubject,...
         ['Beginning test of machine communications.'], '');
    end

    % Update the webpage
    obj.displayStatusWebPage('testmachine');
                    
    % Test the machines in the machineSetConfig
    configStr = obj.machineSetConfig.printToStr;
    obj.log.write(configStr);
    for i = 1:obj.machineSetConfig.getNumMachines()
        config = obj.machineSetConfig.getMachine(i);
        type = config.getResourceType();
        numSimulators = config.getNumSimulators();
        
        % Skip machine if no simulators 
        if ~numSimulators continue; end %#ok<SEPEX>
        % Construct the appropriate test machine and run its
        % communications test method...
        testMachine = type.commsTestFunc(config, obj.hostMachineData.id,...
                                    obj.hostMachineData.osType,...
                                    obj.machineScratchDir,...
                                    obj.auth, obj.log);
        % ...only if that resource hasn't yet been tested
        ID = testMachine.getID();
        commsID = testMachine.getCommsID();
        if isempty(find(strcmp(testedMachines, commsID))) %#ok<EFIND>
            obj.log.write(['Testing machine communications for '...
                           ID '.']);
            tfResult = testMachine.commsTest();
            if tfResult == false
                obj.log.write(['Machine communications for '...
                               ID ' FAILED.']);
                if obj.simNotificationSet.isEnabled()
                    notificationSubject = ['NeuroManager Error'];
                    obj.simNotificationSet.send(notificationSubject,...
                     ['Communications Test with ' ID ' FAILED.'], '');
                end
                testMachine.delete();
                return;
            end
            testedMachines = [testedMachines commsID]; %#ok<AGROW>
            obj.log.write(['Machine communications for '...
                           ID ' passed.']);
        else
            obj.log.write(['Machine communications for '...
                            ID ' already tested.']);
        end
        
        % Test for compiler-MCR compatibility
        if ~(strcmp(obj.MLCompilerVersion, config.getMcrVer()) || ...
             strcmp(obj.MLCompilerVersion, [config.getMcrVer() '.0']))
            obj.log.write(['Config verification for machine ' ID ...
              ' FAILED because of mismatch between version of compiler used (' ...
              obj.MLCompilerVersion ') and MCR version (' ...
              config.getMcrVer() ') given in config file.']);
            tfResult = false;
            return;
        else
            obj.log.write(['Compiler-MCR compatibility for machine ' ...
                           ID ' passed (version ' obj.MLCompilerVersion ...
                           ').']);
        end
        testMachine.delete();
    end
    tfResult = true;
    if obj.simNotificationSet.isEnabled()
        notificationSubject = ['Re: NeuroManager Notice'];
        obj.simNotificationSet.send(notificationSubject,...
         ['Machine communications test PASSED.'], '');
    end
end
