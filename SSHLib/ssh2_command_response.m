function [command_result] = ssh2_command_response(ssh2_struct)
% SSH2_COMMAND_RESPONSE   Returns the host response from the last SSH2 command
%
%   SSH2_COMMAND(SSH2_CONN)
%   Is a quick method to retrieve the command response from the last SSH2
%   command from the remote host.
% 
%   SSH2_COMMAND returns the COMMAND RESPONSE from the last remote command.
%
%see also ssh2, ssh2_commmand, ssh2_simple_command
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


if nargout == 1
    if nargin == 1
        command_result = ssh2_struct.command_result;
    else
        command_result = 0;
    end
else
    if (nargout < 2 || enableprint)
        for i = 1:numel(ssh2_struct.command_result)
           fprintf('%s\n', ssh2_struct.command_result{i});
        end
    end
end
