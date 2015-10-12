function ssh2_struct = ssh2_close(ssh2_struct)
% SSH2_CLOSE   closes an existing SSH2 connection. 
%              This function can be used as the last SSH2 commmand
%              because the connection won't be closed until the very end.
%   SSH2_CLOSE(SSH2_CONN) takes a ssh2_connection, sets it close, and runs
%   it through the ssh2 engine where it is closed at the end. 
% 
%   SSH2_CLOSE returns the SSH2_CONN for future use.
%
%see also ssh2, ssh2_setup, ssh2_config, ssh2_config_publickey, scp, sftp
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


if nargin == 1
    ssh2_struct.close_connection = 1;%;
    ssh2_struct = ssh2(ssh2_struct); %close the connection
else
    ssh2_struct = [];
    help ssh2_close
end