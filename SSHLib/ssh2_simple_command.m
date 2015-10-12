function command_result = ssh2_simple_command(hostname, username, password, command, enableprint)
% SSH2_SIMPLE_COMMAND   connects to host using given username and password.
%                       A command can be given and the output will be
%                       displayed unless supressed.
%
%   SSH2_SIMPLE_COMMAND(HOSTNAME,USERNAME,PASSWORD,COMMAND,[ENABLEPRINTTOSCREEN])
%   Connects to the SSH2 host, HOSTNAME with supplied USERNAME and
%   PASSWORD. Once connected the COMMAND is issues. The output from the 
%   remote host is returned and the connection is closed.
%
%   OPTIONAL INPUTS:
%   -----------------------------------------------------------------------
%   ENABLEPRINTTOSCREEN  force printing the remote host output on screen.
%
% 
%   SSH2_SIMPLE_COMMAND returns a cell array containing the host response.
%
%see also ssh2_command, ssh2, scp_simple_get, scp_simple_put, sftp_simple_get, sftp_simple_put
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


command_result = [];

if nargin < 4
    ssh2_struct = [];
    help ssh2_simple_command
else
    if nargin < 5
        enableprint = 0;
    end

    ssh2_struct = ssh2_config(hostname, username, password);
    ssh2_struct.close_connection = 1; %close connection use

    if nargout == 0
        ssh2_struct = ssh2_command(ssh2_struct, command, enableprint);
    else
        [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, enableprint);
    end
end
