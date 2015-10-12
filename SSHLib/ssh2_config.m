function ssh2_struct = ssh2_config(hostname, username, password, port)
% SSH2_CONFIG   creates a simple SSH2 connection with the
%               specified hostname, username, and password
%
%   SSH2_CONFIG(HOSTNAME,USERNAME,PASSWORD, [PORT])
%   Configures a connection to the host, HOSTNAME with user USERNAME and
%   password, PASSWORD. The returned SSH2_CONN can be used by SSH2_COMMAND 
%   or other SSH2 file transfer commands.
%
%   OPTIONAL INPUTS:
%   -----------------------------------------------------------------------
%   PORT  to specify a non-standard SSH TCP/IP port. Default is 22.
%
% 
%   SSH2_CONFIG returns the SSH2_CONN for future use
%
%see also ssh2_config_publickey, ssh2, ssh2_command, scp_get, scp_put, sftp_get, sftp_put
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


ssh2_struct = ssh2_setup(); %default config
if (nargin >= 3)
    ssh2_struct.hostname = hostname;
    ssh2_struct.username = username;
    ssh2_struct.password = password;
    if nargin >= 4
        ssh2_struct.port = port;
    end
else
    help ssh2_config
end