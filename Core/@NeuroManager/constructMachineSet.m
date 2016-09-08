% ----------------
function constructMachineSet(obj)
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

    % Ensure compatibility with earlier MATLAB Compilation 
    if obj.compiledType ~= obj.machineSetType
        error(['Cannot construct machine set because previous ' ...
               'compilation (' char(obj.compiledType) ') and set type (' ...
               char(obj.machineSetType) ') do not agree. Use the ' ...
               'setMLCompileServer method of NeuroManager ' ... 
               'to set the Simulator type.']);
    end

    % Make the machines in the MachineSetConfig
    obj.machineSet = obj.makeMyMachines(obj.machineScratchDir,...
                                        obj.machineSetType, obj.auth);
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
        