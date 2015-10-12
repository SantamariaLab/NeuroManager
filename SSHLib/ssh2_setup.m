% ssh2_setup
% This file replaces the ssh2_setup provided in the ssh_v2m1_r6 MATLAB
% library. This modified version eliminates automated downloadloading,
% installation, loading and other mechanisms that NeuroManager already
% provides or does not require.
% Please ensure that the Core NeuroManager directory is above the ssh_v2m1_r6
% directory in your MATLAB search path.
% For proper installation procedures please see the NeuroManager User Guide.
% Do not use this file other than with NeuroManager.
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
function ssh2_struct = ssh2_setup(ssh2_struct)
    %disp(['Using Modified ssh2_setup'])
    if nargin ~= 0
        if strcmp(ssh2_struct, '?')
            ssh2_struct = '!';
        else
            error('Bad input to Modified ssh2_setup');
        end
    else
        ssh2_struct.hostname = [];
        ssh2_struct.username = [];
        ssh2_struct.password = [];
        ssh2_struct.port = 22;

        ssh2_struct.connection = [];
        ssh2_struct.authenticated = 0;
        ssh2_struct.autoreconnect = 0;
        ssh2_struct.close_connection = 0;

        ssh2_struct.pem_file = [];
        ssh2_struct.pem_private_key = [];
        ssh2_struct.pem_private_key_password = [];

        ssh2_struct.command = [];
        ssh2_struct.command_session = [];
        ssh2_struct.command_ignore_response = 0;
        ssh2_struct.command_result = [];

        ssh2_struct.sftp = 0;
        ssh2_struct.scp = 0;
        ssh2_struct.sendfiles = 0;
        ssh2_struct.getfiles = 0;

        ssh2_struct.remote_file = [];
        ssh2_struct.local_target_direcory = [];
        ssh2_struct.local_file = [];
        ssh2_struct.remote_target_direcory = [];
        ssh2_struct.remote_file_new_name = [];
        ssh2_struct.remote_file_mode = 0600; %0600 is default

        ssh2_struct.verified_config = 0;

        ssh2_struct.ssh2_java_library_loaded = 1;  
    end
end
