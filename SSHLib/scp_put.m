function ssh2_struct = scp_put(ssh2_struct, localFilename, remotePath, localPath, remoteFilename)
% SCP_PUT   Reuse configured ssh2_connection to SCP local files to remote host.
%
%   SCP_PUT(SSH2_CONN,LOCALFILENAME,[REMOTEPATH],[LOCALPATH],[REMOTEFILENAME])
%   uses a ssh2_connection and uploads the LOCALFILENAME to the remote
%   host using SCP. SSH2_CONN must already be confgured using 
%   ssh2_config or ssh2_config_publickey.
%
%   LOCALFILENAME can be either a single string, or a cell array of strings. 
%   If LOCALFILENAME is a cell array, all files will be downloaded
%   sequentially.
%
%   OPTIONAL INPUTS:
%   -----------------------------------------------------------------------
%   REMOTEPATH specifies a specific path to upload the file to. Otherwise, 
%   the default (home) folder is used.
%   LOCALPATH specifies the folder to find the LOCALFILENAME in the file
%   is outside the working directory.
%   REMOTEFILENAME can be specified to rename the file on the remote host.
%   If LOCALFILENAME is a cell array, REMOTEFILENAME must be too.
%
%   SCP_PUT returns the SSH2_CONN for future use.
%
%see also scp_get, scp_simple_get, scp_simple_put, scp
%
%{
Copyright (c) 2013, David S. Freedman
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the distribution

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
%}

if nargin < 2
    if nargin == 0
        ssh2_struct = [];
    end
    help scp_put
else
    if nargin < 3
        remotePath = '';
    end
    
    if nargin < 4
        localPath = pwd();
    elseif isempty(localPath)
        localPath = pwd();   
    end    

    if nargin >= 5
        ssh2_struct.remote_file_new_name = remoteFilename;
    else 
        remoteFilename = [];
    end
    
    ssh2_struct.sendfiles = 1;
    ssh2_struct.local_file = localFilename;
    ssh2_struct.local_target_direcory = localPath;
    ssh2_struct.remote_target_direcory = remotePath;

    ssh2_struct = scp(ssh2_struct);
end


    
