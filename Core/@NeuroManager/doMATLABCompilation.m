function doMATLABCompilation(obj)
    % Update the webpage
    obj.displayStatusWebPage('MATLABcompiling');

    % Perform the MATLAB Compilation
    % MLCM = MATLAB Compile Machine
    obj.log.write(['Beginning MATLAB compilation.']);
    config = obj.mLCompileConfig.getMachine();
    MLCM = MATLABCompileMachine(config, obj.machineSetType, ...
                obj.machineScratchDir,  obj.ML2CompileDir, ...
                obj.toUploadDir, obj.MLCompiledDir,...
                obj.hostMachineData.id, obj.hostMachineData.osType, ...
                obj.auth, obj.log, obj.simNotificationSet);

    obj.MLCFTL = MLCM.getCompilationFileTransferList();

    obj.preUploadFiles(MLCM);
    
    % files2Compile set in preUploadFiles()
    obj.MLCompilerVersion = MLCM.preCompile(obj.files2Compile); 
    MLCM.compile();
    MLCM.postCompile();
    MLCM.delete();

    % Record the event for later compatibility checks
    obj.compiledType = obj.machineSetType;

    obj.log.write(['MATLAB compilation complete.']);

    % Switch the webpage back to generic initialization activity
    obj.displayStatusWebPage('initial');
end
