function ssh2_struct = sftp_simple_get(hostname, username, password, remoteFilename, localPath, remotePath)
% SFTP_SIMPLE_GET   creates a simple SSH2 connection and retrieves a remote file
%                   NOTE: BECAUSE OF THE WAY MATLAB WORKS WITH JAVA BYTE ARRAYS
%                   GARYMED-SSH2 is CUMBERSOME TO USE WITH SFTP GETS.
%                   SCP IS USED INSTEAD
%
%   SFTP_SIMPLE_GET(HOSTNAME,USERNAME,PASSWORD,REMOTEFILENAME,[LOCALPATH],[REMOTEPATH])
%   Connects to the SSH2 host, HOSTNAME with supplied USERNAME and
%   PASSWORD. Once connected the REMOTEFILENAME is downloaded from the
%   remote host using SFTP. The connection is then closed.
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
%   SFTP_SIMPLE_GET returns the SSH2_CONN for future use.
%
%see also sftp_simple_put, sftp, sftp_get, sftp_put, ssh2_simple_command
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


if nargin < 4
    ssh2_struct = [];
    help sftp_simple_get
else
    if nargin < 5
        localPath = pwd();
    elseif isempty(localPath)
        localPath = pwd();   
    end    
    
    if nargin < 6
        remotePath = '';         
    end
    

    ssh2_struct = ssh2_config(hostname, username, password);
    ssh2_struct.close_connection = 1; %close connection use
    ssh2_struct = sftp_get(ssh2_struct, remoteFilename, localPath, remotePath);
end

