classdef RSCloud < OSCloud
    properties
    end
    methods
        function obj = RSCloud(config)
            obj = obj@OSCloud(config);
        end

        % -----
        % true/success or false/failure
        function tf = deleteServer(obj, serverID)
            % Check for existence first. If doesn't exist return false.
            if ~obj.existsServerID(serverID)
                tf = false;
                return;
            end
            
%             % Need to remove any associated floating IPs too so don't have
%             % a floating IP leak
%             ipID = obj.disassociateFloatingIP(serverID);
%             obj.deallocateFloatingIP(ipID);

            % Delete the server
            addressExt = ['/servers/' serverID];
            [~, ~, ~] =...
                obj.issueComputeEndpointCommand('', {'-X DELETE '}, addressExt);

            
            % Wait for successful termination
            % Watching for DELETED doesn't seem to work because the ability
            % to see DELETED goes away.
            % Later add a max number of checks before return false.
            while obj.existsServerID(serverID)
                pause(obj.waitingDelay);
            end
            tf = true;
        end

        
        % -----
        % Creates a single server and assigns it a floating ip address
        function [name, serverID, ipAddr] = ...
                            createServer(obj, name, imageRef, flavorRef)
            % At this level we reject if a server with that name already
            % exists, although OpenStack does allow servers with same name
            % and different IDs.
            if obj.existsServerName(name)
                name = ''; serverID = ''; ipAddr = '';
                return;
            end
            obj.imageRef = imageRef;
            obj.flavorRef = flavorRef;
            responseBody = ...
                struct('server', struct('tenant_id',    obj.OS_TENANT_NAME, ...
                                        'user_id',      obj.OS_USERNAME, ...
                                        'key_name',     obj.OS_KEY_NAME, ...
                                        'name',         name, ...
                                        'imageRef',     obj.imageRef, ...
                                        'flavorRef',    obj.flavorRef) ...
                                        );
            addressExt = '/servers';
            [~, answer, ~] = obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            server = loadjson(answer);
            serverID = server.server.id;
            
            % need to wait until get full creation
            [status, powerState, progress] = obj.getCreateServerProgress(serverID)
            while strcmp(status, 'BUILD')
                pause(obj.waitingDelay);
                [status, powerState, ~] = obj.getCreateServerProgress(serverID);
            end            
            
            while powerState ~= 1
                pause(obj.waitingDelay);
                [status, powerState, progress] = obj.getCreateServerProgress(serverID)
            end
            
            % Now give it an external IP
%             ipAddr = obj.allocateFloatingIP();
%             if ~isempty(ipAddr)
%                 tf = obj.associateFloatingIP(serverID, ipAddr);
%                 if ~tf
%                     name = ''; serverID = ''; ipAddr = '';
%                 end
%             end
            [name, status, ipAddr] = obj.getServerData(serverID)
        end
                
        % -----
        function floatingIPs = listFloatingIPs(obj)
            addressExt = '/floating-ips';
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            if ~strfind(answer, '404')
                floatingIPs = loadjson(answer);
            else 
                floatingIPs = {};
            end
        end

        % -----
        function [name, status, ipAddr] = getServerData(obj, serverID)
            details = obj.getServerDetailsID(serverID);
            name = details.server.name;
            status = details.server.status;
%             ntwk = obj.getNetwork();
            ipAddr = details.server.accessIPv4;
%             ipAddr = details.server.addresses.(ntwk){1,1}.addr;
        end
        
        % -----
        function token = getToken(obj)
            if ~isunix
                cmd = [fullfile(obj.curlDir, 'curl -sS ') ...
                       '-X POST ' obj.OS_IdentityEndpoint '/tokens '...
                       '-H "Content-Type: application/json" '...
                       '-d "{\"auth\": {\"RAX-KSKEY:apiKeyCredentials\":  '...
                       '{\"username\": \"' obj.OS_USERNAME '\", '...
                        '\"apiKey\": \"' obj.OS_PASSWORD '\"}'...
                       '}}" '...
                       ]
%                        '--key-type PEM '...
%                        ['--key ' obj.localKeyFile ' ']...
            else
                % UNIX version not implemented yet
                %     cmd = ['./curl-7.46.0-win64-mingw/bin/curl --help'];
            end
            [~, answer] = system(cmd);
            data = loadjson(answer); % Need check for rejection of request
            token = data.access.token.id;
        end
    end
end
