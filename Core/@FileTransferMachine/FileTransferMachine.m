% FileTransferMachine class
% Adds host-to-target, target-to-host, and target-target file transfer
% methods to the RealMachine class.  Makes use of the MATLAB SSH2 library.
classdef FileTransferMachine < RealMachine
    properties
        hostOS; % The OS of the host for choosing download approach
    end
    
    methods
        function obj = FileTransferMachine(config, hostId, hostOs, auth)
                 obj = obj@RealMachine(config, hostId, auth);
                 obj.hostOS = hostOs;
        end        
        
        % ----------------
        function fileToMachine(obj, hostPath, targetPath)
        % Transfers a file from the host to the filesystem machine
        % Use full paths including filename for both
            if exist(hostPath, 'file')
                if strcmp(obj.hostID, obj.id)
                    copyfile(hostPath, targetPath);
                else
                    [hostPathStr,   hostName,   hostExt]...
                                               = fileparts(hostPath);
                    [targetPathstr, targetName, targetExt]...
                                               = fileparts(targetPath);
                    obj.fsConnection =...
                        scp_put(obj.fsConnection,...
                                [hostName, hostExt],  path2UNIX(targetPathstr),...
                                hostPathStr, [targetName, targetExt]);
                    % Might be some return values from above to deal with
                end
            else
                error(['SimMachine:FileToMachine Error: File '...
                       hostPath ' does not exist.']);
            end
        end
        
        
        % -------------
        function fileListToMachine(obj, fileList, hostDir, targetDir)
            % Transfers a cell array of files from host to filesystem
            % machine 
            if strcmp(obj.hostID, obj.id)
                for i=1:length(fileList)
                    copyfile(fullfile(hostDir, fileList{i}), targetDir);
                end
            else
                if ~isempty(fileList)
                    obj.fsConnection = scp_put(obj.fsConnection, fileList,...
                                               path2UNIX(targetDir),...
                                               hostDir, fileList);
                end
            end
        end
        
        % -------------
        function fileListToMachineRename(obj, fileList, newFileList,...
                                              hostDir, targetDir)
            % Transfers a cell array of files from host to filesystem
            % machine and renames them with the names in newfilelist
            if ~isempty(fileList)
                if strcmp(obj.hostID, obj.id)
                    for i=1:length(fileList)
                        copyfile(fullfile(hostDir, fileList{i}),...
                                 fullfile(targetDir, newFileList{i}));
                    end
                else
                    obj.fsConnection = scp_put(obj.fsConnection, fileList,...
                                               path2UNIX(targetDir),...
                                               hostDir, newFileList);
                end 
            end
        end
        
        % ----------
        function remoteCopy(obj, sourceDir, destDir, fileList) 
        % Dir to dir copy of (cell array) list of files on same remote UNIX machine
            command = ['cd ' path2UNIX(sourceDir) ';'];
            if ~isempty(fileList)
                command = [command ' cp -p ' strjoin(fileList, ' ') ' ' ...
                           path2UNIX(destDir) ';']; 
            end
            obj.issueMachineCommand(command, CommandType.FILESYSTEM);
        end 
        
        % ----------------
        function fileFromMachine(obj, hostFolder, targetPath)
        % Transfers a file from target fsmachine to host directory
            [targetPathStr, targetName, targetExt]  = fileparts(targetPath);
            if strcmp(obj.hostID, obj.id)
                copyfile(targetPath, hostFolder);
            else
                obj.fsConnection = scp_get(obj.fsConnection,...
                                {[targetName targetExt]}, hostFolder,...
                                path2UNIX(targetPathStr));                
            end
        end
        
        % ---------------
        % FileFromMachineNoWait - see separate file
    end
    
    methods (Access = protected)
        createDownloadExpectFile(obj, hostDir, targetPath)
	end
    
    methods (Static)
        % -------------
        function tfResult = fileListExist(hostDir, fileList)
        % Checks the existence of fileList in hostDir.  Returns false if 
        % any of the files does not exist. Returns true if the list is empty.
        % empty filenames ('') do not produce false, in contrast to the
        % actual exist() MATLAB function.
            tfResult = true;
            if ~isempty(fileList)
                for i=1:length(fileList)
                    if ~isempty(fileList{i})
                        if ~exist(fullfile(hostDir, fileList{i}), 'file')
                            tfResult = false;
                            return;
                        end
                    end
                end
            end
        end
    end
end
