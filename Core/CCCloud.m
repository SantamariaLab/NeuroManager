classdef CCCloud < OSCloud
    properties
    end
    methods
        function obj = CCCloud(cloudData)
            obj = obj@OSCloud(cloudData);
        end

        % -----
        % true/success or false/failure
        function tf = deleteServer(obj, serverID)
            % Check for existence first. If doesn't exist return false.
            if ~obj.existsServerID(serverID)
                tf = false;
                return;
            end
            
            % Need to remove any associated floating IPs too so don't have
            % a floating IP leak
            ipID = obj.disassociateFloatingIP(serverID);
            obj.deallocateFloatingIP(ipID);

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
            [status, powerState, progress] = obj.getCreateServerProgress(serverID);
            while (strcmp(status, 'BUILD') && ~strcmp(progress, '100'))
                pause(obj.waitingDelay);
                [status, powerState, progress] = obj.getCreateServerProgress(serverID);
            end            
            
            while powerState ~= 1
                pause(obj.waitingDelay);
                [~, powerState, ~] = obj.getCreateServerProgress(serverID);
            end
            
            % Now give it an external IP
            ipAddr = obj.allocateFloatingIP();
            if ~isempty(ipAddr)
                tf = obj.associateFloatingIP(serverID, ipAddr);
                if ~tf
                    name = ''; serverID = ''; ipAddr = '';
                end
            end
        end
        
        
        
             % -----
        % need to check for allocation restriction
        function ip = allocateFloatingIP(obj)
            responseBody = struct('pool', 'ext-net');
            addressExt = '/os-floating-ips';
            [~, answer, ~] = obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            ipdata = loadjson(answer);
            ip = ipdata.floating_ip.ip;
        end

        
        % -----
        function tf = deallocateFloatingIP(obj, ipID)
            addressExt = ['/os-floating-ips/' ipID];
            [~, ~, ~] = obj.issueComputeEndpointCommand('', {'-X DELETE '}, addressExt);
            
            % Verify (need delay?)
            if obj.existsFloatingIP(ipID)
                tf = false;
            else
                tf = true;
            end
        end
        
        
        % -----
        % Need to check server data to ensure success
        function tf = associateFloatingIP(obj, serverID, ipAddr)
            responseBody = struct('addFloatingIp', struct('address', ipAddr));
            addressExt = ['/servers/' serverID '/action'];
            [~, ~, ~] = obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            
            [~, ~, ipAddrActual] = obj.getServerData(serverID);
            if strcmp(ipAddr, ipAddrActual)
                tf = true;
            else
                tf = false;
            end
        end

   
        
              % -----
        function ipID = disassociateFloatingIP(obj, serverID)
            % Get the ip associated with the server
            [~, ~, ipAddr] = obj.getServerData(serverID);
            
            % Get the ip's ID
            floatingIps = obj.listFloatingIPs();
            numIps = length(floatingIps.floating_ips);
            ipID = '';
            for i = 1:numIps
                if strcmp(floatingIps.floating_ips{1,i}.ip, ipAddr)
                    ipID = floatingIps.floating_ips{1,i}.id;
                    break;
                end
            end
            
            % Disassociate the ip using the ID
            if ~isempty(ipID)
                responseBody = struct('removeFloatingIp', struct('address', ipID));
                addressExt = ['/servers/' serverID '/action'];
                [~, ~, ~] =...
                    obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            end
        end
        
  
        
        
        
        % -----
        function floatingIPs = listFloatingIPs(obj)
            addressExt = '/os-floating-ips';
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            answer
            if ~isempty(answer)
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
            ntwk = obj.getNetwork();
            extAddrRt = obj.getExtAddressRoot();
            numAddresses = size(details.server.addresses.(ntwk), 2);
            % Grab the first floating address and return it.
            % Not sure about multiple floating addresses, but I doubt it's
            % allowed.
            ipAddr = '';
            for i = numAddresses
                if strcmp(details.server.addresses.(ntwk){1,i}.([extAddrRt '_0x3A_type']),...
                        'floating')
                    ipAddr = details.server.addresses.(ntwk){1,i}.addr;
                    break;
                end
            end
        end
        
        % -----
        function token = getToken(obj)
            if ~isunix
                cmd = [fullfile(obj.curldir, 'curl -sS ') ...
                       '-X POST ' obj.OS_IdentityEndpoint '/tokens '...
                       '-H "Content-Type: application/json" '...
                       '--key-type PEM '...
                       ['--key ' obj.localKeyFile ' ']...
                       '-d "{\"auth\": {\"tenantName\": \"' ...
                       obj.OS_TENANT_NAME '\", '...
                       '\"passwordCredentials\":  '...
                       '{\"username\": \"' obj.OS_USERNAME '\", '...
                        '\"password\": \"' obj.OS_PASSWORD '\"}'...
                       '}}" '...
                       ];
            else
                % UNIX version not implemented yet
                %     cmd = ['./curl-7.46.0-win64-mingw/bin/curl --help'];
            end
            [~, answer] = system(cmd);
            data = loadjson(answer);
            token = data.access.token.id;
        end
    end
end
