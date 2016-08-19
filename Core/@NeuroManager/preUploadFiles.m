% This aspect of preUploadFiles handles things that need to be done before
% machine or simulator construction
function preUploadFiles(obj, machine)
    % Create a dummy host-only Simulator of the proper type in
    % order to determine files to compile and place them in the 
    simulatorID = 'dummy4compile';
    type = obj.machineSetType;
    dummySim  = type.constrFunc(simulatorID, machine,...
                                obj.log, obj.simNotificationSet);
   
    % Query the simulator for the files to compile and to upload
    % separately from compilation
    [baseListComp, baseListNonComp] = splitFileList(dummySim.getBaseSimulatorFileList())
    copyFileListToDirectory(baseListComp, obj.simCoreDir, obj.ML2CompileDir);
    copyFileListToDirectory(baseListNonComp, obj.simCoreDir, obj.toUploadDir);

    [extListComp, extListNonComp]= splitFileList(dummySim.getExtendedSimulatorFileList())
    copyFileListToDirectory(extListComp, obj.simCoreDir, obj.ML2CompileDir);
    copyFileListToDirectory(extListNonComp, obj.simCoreDir, obj.toUploadDir);

    [reqdCustListComp, reqdCustListNonComp] = splitFileList(dummySim.getReqdCustomFileList())
    copyFileListToDirectory(reqdCustListComp, obj.customSimDir, obj.ML2CompileDir);
    copyFileListToDirectory(reqdCustListNonComp, obj.customSimDir, obj.toUploadDir);

    [addlCustListComp, addlCustListNonComp] = splitFileList(dummySim.getAddlCustomFileList())
    copyFileListToDirectory(addlCustListComp, obj.customSimDir, obj.ML2CompileDir);
    copyFileListToDirectory(addlCustListNonComp, obj.customSimDir, obj.toUploadDir);
    
    modelFileList = dummySim.getModelFileList()
    copyFileListToDirectory(modelFileList, obj.modelFileDir, obj.toModelRepoDir);

    dummySim.delete();
    
    obj.files2Compile = [baseListComp extListComp reqdCustListComp addlCustListComp];
    obj.files2Upload =  [baseListNonComp extListNonComp reqdCustListNonComp addlCustListNonComp];
    obj.modelFiles2Upload = modelFileList;
end

% Temp HANDLE ERRORS SOON
function copyFileListToDirectory(list, sourceDir, destDir)
%     list 
%     sourceDir
%     destDir
    if ~isempty(list)
        numFiles = length(list);
        for i=1:numFiles
%             f = fullfile(sourceDir, list{i})
%             d = destDir
            copyfile(fullfile(sourceDir, list{i}), destDir);
        end
    end
end

% SplitFileList
% A utility function that splits a list of filenames into those
% that are *.m filenames and those that are not. All lists are cell arrays.
function [mfileList, nonMfileList] = splitFileList(fileList)
    % Cell arrays appear to make this approach necessary.
    j = 1; k = 1;
    nonMfileList = {}; mfileList = {};
    for i=1:length(fileList)
        if isempty(regexp(fileList{i}, '^\w*\.m$', 'once'))
            nonMfileList{j} = fileList{i}; %#ok<AGROW>
            j = j+1;
        else
            mfileList{k} = fileList{i}; %#ok<AGROW>
            k = k+1;
        end
    end
end
