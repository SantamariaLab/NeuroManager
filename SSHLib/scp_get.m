function ssh2_struct = scp_get(ssh2_struct, remoteFilename, localPath, remotePath)
% SCP_GET   Reuse configured ssh2_connection to SCP remote files to local host
%
%   SCP_GET(SSH2_CONN,REMOTEFILENAME,[LOCALPATH],[REMOTEPATH])
%   uses a ssh2_connection and downloads the REMOTEFILENAME from the remote
%   host using SCP. SSH2_CONN must already be confgured using 
%   ssh2_config or ssh2_config_publickey.
%
%   REMOTEFILENAME can be either a single string, or a cell array of strings. 
%   If REMOTEFILENAME is a cell array, all files will be downloaded
%   sequentially.
%
%   OPTIONAL INPUTS:
%   -----------------------------------------------------------------------
%   LOCALPATH specifies the folder to download the remote file to.
%   Otherwise the working directory is used.
%   REMOTEPATH specifies a specific path on the remote host to look for the 
%   file to download. Otherwise, the default (home) folder is used.
%
%   SCP_GET returns the SSH2_CONN for future use.
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
    help scp_get
else
    if nargin < 3
        localPath = pwd();
    elseif isempty(localPath)
        localPath = pwd();        
    end
    if nargin < 4
        remotePath = '';          
    end

    ssh2_struct.getfiles = 1;
    ssh2_struct.remote_file = remoteFilename;
    ssh2_struct.local_target_direcory = localPath;
    ssh2_struct.remote_target_direcory = remotePath;
    %ssh2_struct.local_file = localFilename; unused in SCP, filename will
    %be taken from remoteFilename

    ssh2_struct = scp(ssh2_struct);
end