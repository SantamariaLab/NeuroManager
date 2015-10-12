function [ssh2_struct, command_result] = ssh2_command(ssh2_struct, command, enableprint)
% SSH2_COMMAND   Reuses a SSH2 connection and issues the specified command
%
%   [SSH2_CONN, [COMMAND_RESULT]] = SSH2_COMMAND(SSH2_CONN,COMMAND,[ENABLEPRINTTOSCREEN])
%   Connects to the SSH2 host with a configured SSH2_CONN. Once connected 
%   the COMMAND is issues. The output from the remote host is returned.
%   The connection to the remote host is still open the function completes.
%   When finished, close the connection with SSH2_CLOSE(SSH2_CONN)
%
%   OPTIONAL INPUTS:
%   -----------------------------------------------------------------------
%   ENABLEPRINTTOSCREEN  force printing the remote host output on screen.
%
% 
%   SSH2_COMMAND returns the SSH2_CONN for future use and the 
%   cell array containing the host response.
%
%see also ssh2, ssh2_config, ssh2_config_publickey, ssh2_simple_command
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


if nargin < 3
    enableprint = 0;
end

ssh2_struct.command = command;

%% SSH TO HOST
ssh2_struct = ssh2(ssh2_struct);

%% OUTPUT RESPONSE FROM HOST
if (nargout < 2 || enableprint)
    for i = 1:numel(ssh2_struct.command_result)
       fprintf('%s\n', ssh2_struct.command_result{i});
    end
end

if nargout > 1
    command_result = ssh2_struct.command_result;
end
if nargout == 0
    clear ssh2_struct;
end
