function ssh2_struct = ssh2_config_publickey(hostname, username, pemFile, pemFilePassword, port)
% SSH2_CONFIG_PUBLICKEY   setups a  SSH2 connection with the
%                         specified hostname, username, and public key
%
%   SSH2_CONFIG_PUBLICKEY(HOSTNAME,USERNAME,PRIVATE_KEY,PRIVATE_KEY_PASSWORD, [PORT])
%   Configures a connection to the host, HOSTNAME with user USERNAME. The
%   private key can be a path to a private key file or a private key string
%   since this is unlikey they can be confused. The password to unencrypt
%   the private key us supplied as PRIVATE_KEY_PASSWORD. The returned
%   SSH2_CONN can be used by SSH2_COMMAND or other SSH2 file transfer
%   commands.
%
%   OPTIONAL INPUTS:
%   -----------------------------------------------------------------------
%   PORT  to specify a non-standard SSH TCP/IP port. Default is 22.
%
% 
%   SSH2_CONFIG_PUBLICKEY returns the SSH2_CONN for future use
%
%see also ssh2_config, ssh2, ssh2_command, scp_get, scp_put, sftp_get, sftp_put
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

if (nargin >= 4)
    ssh2_struct.hostname = hostname;
    ssh2_struct.username = username;
    if (exist(pemFile,'file'))
        ssh2_struct.pem_file = pemFile;
    else
        ssh2_struct.pem_private_key = pemFile;
    end

    ssh2_struct.pem_private_key_password = pemFilePassword;

    if nargin >= 5
        ssh2_struct.port = port;
    end
else
    help ssh2_config_publickey
end