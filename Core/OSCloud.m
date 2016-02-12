% OSCloud
%
% To Do
% Higher priority
%  DONE -- ****Be consistent with local copy refreshed by refresh....
%  -- Ensure using key in curl calls (--key  and --pass options)
%  -- Check for allocations in # servers, # IPs
%  DONE -- Check for existence before using
%  DONE -- Add floating IP as part of adding a server
%  DONE -- Remove floating IP before deleting server
%  DONE -- Improve token handling
%  -- Integrate with NeuroManager in multiple ways
%  -- Get better security solution from Chameleon
%  -- Move local values (e.g., see constructor) out like in the rest of
%  NeuroManager
%  -- Support UNIX host
%  -- Provenance stuff
%
% Lower priority
%  -- Push as much as possible up to Cloud so that the OS-specific stuff
%       is isolated in this class
%  -- Pass in image and flavor
%  -- Create tables for image and flavor
%
% Done


classdef OSCloud < Cloud
    properties (Access=private)
        OS_IdentityEndpoint;
        OS_ComputeEndpoint;
        OS_TENANT_NAME;
        OS_USERNAME;
        OS_PASSWORD;
        OS_KEY_NAME;    % on the cloud
        localKeyFile;   % on the NM host
        curldir;
        network;
        extAddressRoot; 
        currentComputeToken;
        waitingDelay; % seconds
        imageRef;
        flavorRef;
    end
    
    methods
        function obj = OSCloud(machineData, xCmpMach, xCmpDir,...
                                    hostID, hostOS, auth)
            obj = obj@Cloud(machineData, xCmpMach, xCmpDir,...
                                    hostID, hostOS, auth);
            obj.OS_IdentityEndpoint = ...
                'https://openstack.tacc.chameleoncloud.org:5000/v2.0/tokens';
            obj.OS_ComputeEndpoint = ...
                'https://openstack.tacc.chameleoncloud.org:8774/v2/CH-817259';
            obj.OS_TENANT_NAME = 'CH-817259';
            obj.OS_USERNAME = 'stockton';
            obj.OS_PASSWORD = 'Neurons55';
            obj.OS_KEY_NAME = 'dbs Laptop Key';
            obj.localKeyFile = 'C:\Users\David\Dropbox\Documents\SantamariaLab\Projects\ProjNeuroMan\dbsLocalMachine\DBSSSH3';
            obj.curldir = ...
                'C:/Users/David/Dropbox/Documents/SantamariaLab/Projects/ProjNeuroMan/CloudStuff/curl-7.46.0-win64-mingw/bin/';
            obj.network = ...
                'CH_0x2D_817259_0x2D_net';  
            % Not sure where this comes from
            obj.extAddressRoot = 'OS_0x2D_EXT_0x2D_IPS'; 
            obj.waitingDelay = 0.25;
            obj.currentComputeToken = obj.getToken();
            obj.imageRef = 'http://openstack.tacc.chameleoncloud.org:8774/CH-817259/images/4c40655f-59ac-4600-bec2-8ecf6333d655';
            obj.flavorRef = 'http://openstack.tacc.chameleoncloud.org:8774/CH-817259/flavors/3';
        end
        
       
        % -----
        % Creates a single server and assigns it a floating ip address
        function [name, serverID, ipAddr] = createServer(obj, name)
            % At this level we reject if a server with that name already
            % exists, although OpenStack does allow servers with same name
            % and different IDs.
            if obj.existsServerName(name)
                name = ''; serverID = ''; ipAddr = '';
                return;
            end
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
            [status, progress] = obj.getCreateServerProgress(serverID);
            while (strcmp(status, 'BUILD') && ~strcmp(progress, '100'))
                pause(obj.waitingDelay);
                [status, progress] = obj.getCreateServerProgress(serverID);
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
        function [status, progress] = getCreateServerProgress(obj, serverID)
            addressExt = ['/servers/' serverID];
            [~, answer, ~] =...
                obj.issueComputeEndpointCommand('', {'-X GET '}, addressExt);
            info = loadjson(answer);
            progress = info.server.progress;
            status = info.server.status;
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
        % not currently used
        function servers = listServers(obj)
            addressExt = '/servers';
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            servers = loadjson(answer);
        end

        
        % -----
        % not currently used
        function images = listImages(obj)
            addressExt = '/images';
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            images = loadjson(answer);
        end
        
         
        % -----
        % not currently used
        function keypairs = listKeypairs(obj)
            addressExt = '/os-keypairs';
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            keypairs = loadjson(answer);
        end

        
        % -----
        function floatingIPs = listFloatingIPs(obj)
            addressExt = '/os-floating-ips';
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            floatingIPs = loadjson(answer);
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
        function success = suspendServer(obj, serverID)
            responseBody = struct('suspend', 'null');
            addressExt = ['/servers/' serverID '/action'];
            [~, ~, ~] =...
                obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            
            % Need to set a time or loop limit 
            while ~strcmp(obj.getServerStatusID(serverID), 'SUSPENDED')
                pause(obj.waitingDelay);
            end
            success = true;
        end

        
        % -----
        function success = resumeServer(obj, serverID)
            responseBody = struct('resume', 'null');
            addressExt = ['/servers/' serverID '/action'];

            % Need to set a time or loop limit 
            [~, ~, ~] = obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            while ~strcmp(obj.getServerStatusID(serverID), 'ACTIVE')
                pause(obj.waitingDelay);
            end
            success = true;
        end
        
        
        % -----
        function [serverData, numServers] = getAllServersData(obj)
            addressExt = '/servers';
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            serverData = loadjson(answer);
            numServers = size(serverData.servers, 2);
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
        function tf = existsFloatingIP(obj, ipID)
            floatingIPs = obj.listFloatingIPs();
            numIPs = length(floatingIPs.floating_ips);
            tf = false;
            for i = 1:numIPs
                if strcmp(floatingIPs.floating_ips{1,i}.id, ipID)
                    tf = true;
                    break;
                end
            end
        end
        
        
        % -----
        function tf = existsServerID(obj, id)
            [data, numServers] = obj.getAllServersData();
            tf = false;
            for i = 1:numServers
                if strcmp(data.servers{1,i}.id, id)
                    tf = true;
                    break;
                end
            end
        end
        
        
        % -----
        function tf = existsServerName(obj, name)
            [data, numServers] = obj.getAllServersData();
            tf = false;
            for i = 1:numServers
                if strcmp(data.servers{1,i}.name, name)
                    tf = true;
                    break;
                end
            end
        end
        
        
        % -----
        function status = getServerStatusID(obj, id)
            details = obj.getServerDetailsID(id);
            status = details.server.status;
        end

        
        % -----
        function status = getServerStatusName(obj, name)
            id = obj.serverIdFromName(name);
            details = obj.getServerDetailsID(id);
            status = details.server.status;
        end
        
        
        % -----
        function id = serverIdFromName(obj, name)
            [serverData, numServers] = obj.getAllServersData();
            id = '';
            for i = 1:numServers
                if strcmp(name, serverData.servers{1,i}.name)
                    id = serverData.servers{1,i}.id;
                    break;
                end
            end
        end
        
        
        % -----
        function name = serverNameFromId(obj, id)
            [serverData, numServers] = obj.getAllServersData();
            name = '';
            for i = 1:numServers
                if strcmp(id, serverData.servers{1,i}.id)
                    name = serverData.servers{1,i}.name;
                    break;
                end
            end
        end
        
        
        % ------
        function details = getServerDetailsID(obj, id)
            addressExt = ['/servers/' id];
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            details = loadjson(answer);
        end
    
        
        % -----
        function details = getServerDetailsName(obj, name)
            id = obj.serverIdFromName(name);
            details = obj.getServerDetailsID(id);
        end
        
        
        % -----
        function network = getNetwork(obj)
            network = obj.network;
        end
        
        
        % -----
        function extAddressRoot = getExtAddressRoot(obj)
            extAddressRoot = obj.extAddressRoot;
        end
        
        
        % -----
%         function getQuotas(obj)
%              cmd = [fullfile(obj.curldir, 'curl -sS') ...
%                     ' -H "X-Auth-Token: ' obj.currentComputeToken '" ' ...
%                     ' -H "Content-Type: application/json" '...
%                     ' -X GET ' [obj.OS_ComputeEndpoint '/os-quota-class-sets/' obj.OS_TENANT_NAME]]
% %                     ' -X GET ' [obj.OS_ComputeEndpoint '/os-quota-class-sets/' 'cores']];
%             [Qresult, Qanswer] = system(cmd)
%         end

        
        % ----- NOT COMPLETE SAVE TILL LATER
%         function id = createServers(obj, nameBase, minNum, maxNum)
%             % Need to: check for apriori existence -return empty id +
%             % error message if already exists
%             % Check for going over allocation
%             % Wait while spawning
%             % Automatically get and associate a floating IP
%             % Output a cell array of ids, names, and IP addresses, and
%             % error messages if appropriate
%             data = ['"{' ...
%                     '\"server\": {' ...
%                     ['\"tenant_id\": \"' obj.OS_TENANT_NAME '\", '] ...
%                     ['\"user_id\": \"' obj.OS_USERNAME '\", '] ... 
%                     ['\"key_name\": \"' obj.OS_KEY_NAME '\", '] ...
%                     ['\"name\": \"' nameBase '\", '] ...
%                     '\"imageRef\": \"http://openstack.tacc.chameleoncloud.org:8774/CH-817259/images/4c40655f-59ac-4600-bec2-8ecf6333d655\", ' ...
%                     '\"flavorRef\": \"http://openstack.tacc.chameleoncloud.org:8774/CH-817259/flavors/3\", ' ...
%                     ['\"min_count\": \"' num2str(minNum) '\", '] ...
%                     ['\"max_count\": \"' num2str(maxNum) ' \"'] ...
%                     '}' ...
%                     '}"'];
%             address = [obj.OS_ComputeEndpoint '/servers'];
%             [result, answer] = obj.issueComputeEndpointCommand(data, address)
%             id = '';
%         end

    end
    
    methods (Access=private)
        % -----
        function token = getToken(obj)
            if ~isunix
                cmd = [fullfile(obj.curldir, 'curl -sS ') ...
                       '-X POST ' obj.OS_IdentityEndpoint ' '...
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
        
        
        % ------
        % data is a json string representing the data body
        % options is a cell array of option strings
        % address is the url to which to write
        function [result, answer, responseCode] = ...
                issueComputeEndpointCommand(obj, responseBody, options, addressExt)
            cmd = [fullfile(obj.curldir, 'curl -sS ') ...
                   '-H "X-Auth-Token: ' obj.currentComputeToken '" '...
                   '-H "Content-Type: application/json " '...
                   '--key-type PEM '...
                   ['--key ' obj.localKeyFile ' ']...
                   '--write-out "%{http_code}" '];
            numOptions = size(options, 2);
            for i = 1:numOptions
                cmd = [cmd ' ' options{1,i}]; %#ok<AGROW>
            end
            if ~isempty(responseBody)
                % Convert to json format then attach to the command
                data = ['"' strrep(savejson('', responseBody, 'Compact',1), '"', '\"') '"'];
                cmd = [cmd ' -d ' data ' '];
            end
            address = [obj.OS_ComputeEndpoint addressExt];
            cmd = [cmd address];
            
            % Issue command and parse the answer into response body and
            % response code
            [result, rawAnswer] = system(cmd);
            parseRegExp = '^(.*})(\d*)$';
            responseCode = regexprep(rawAnswer, parseRegExp, '$2');

            % If the token expired, get a new one and resubmit the command
            % Reference: 
            % http://developer.openstack.org/api-guide/quick-start/api-quick-start.html#openstack-api-quick-guide
            while strcmp(responseCode, '401')
                % Remove the disp when finally verify that this is working
                disp('>>>> Refreshing Compute token. <<<<')
                obj.currentComputeToken = obj.getToken();
                [result, rawAnswer] = system(cmd);
                responseCode = regexprep(rawAnswer, parseRegExp, '$2');
            end
            answer = regexprep(rawAnswer, parseRegExp, '$1');
        end
    end
end
