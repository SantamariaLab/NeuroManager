% ssh2_setup
% This file replaces the ssh2_setup provided in the ssh_v2m1_r6 MATLAB
% library. This modified version eliminates automated downloadloading,
% installation, loading and other mechanisms that NeuroManager already
% provides or does not require.
% Please ensure that the Core NeuroManager directory is above the ssh_v2m1_r6
% directory in your MATLAB search path.
% For proper installation procedures please see the NeuroManager User Guide.
% Do not use this file other than with NeuroManager.
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
