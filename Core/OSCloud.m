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


classdef OSCloud < handle
    properties (Access=protected)
        OS_IdentityEndpoint;
        OS_ComputeEndpoint;
        OS_TENANT_NAME;
        OS_USERNAME;
        OS_PASSWORD;
        OS_KEY_NAME;    % on the cloud
        localKeyFile;   % on the NM host
        curlDir;
        network;
        powerStatePhrase;   % better terminology and handling necessary
        extAddressRoot; 
        currentComputeToken;
        waitingDelay; % seconds
        imageRef;
        flavorRef;
    end
    methods(Abstract)
        getToken(obj)
        getServerData(obj)
        listFloatingIPs(obj)
        createServer(obj)
        deleteServer(obj)
    end
    methods
        function obj = OSCloud(config)
            obj.OS_IdentityEndpoint = config.OS_IdentityEndpoint;
            obj.OS_ComputeEndpoint = config.OS_ComputeEndpoint;
            obj.OS_TENANT_NAME = config.OS_TENANT_NAME;
            obj.OS_USERNAME = config.OS_USERNAME;
            obj.OS_PASSWORD = config.OS_PASSWORD;
            obj.OS_KEY_NAME = config.OS_KEY_NAME;
            obj.network = config.network;
            obj.powerStatePhrase = config.powerStatePhrase;
            % Not sure where this comes from
            obj.extAddressRoot = config.extAddressRoot;

            % -----
            obj.localKeyFile = config.keyFile;
            obj.curlDir = config.curlDir;
            obj.waitingDelay = 0.25;
            obj.currentComputeToken = obj.getToken();
        end

        
        % -----
        function [status, powerState, progress] = getCreateServerProgress(obj, serverID)
            addressExt = ['/servers/' serverID];
            [~, answer, ~] =...
                obj.issueComputeEndpointCommand('', {'-X GET '}, addressExt);
            info = loadjson(answer);
            status = info.server.status;
            powerState = info.server.(obj.powerStatePhrase);
            progress = info.server.progress;
        end
        
        
        % ----- 
        function servers = listServers(obj)
            addressExt = '/servers';
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            servers = loadjson(answer);
        end

        
        % -----
        function images = listImages(obj)
            addressExt = '/images';
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            images = loadjson(answer);
        end
        
        % -----
        function images = listFlavors(obj)
            addressExt = '/flavors';
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
        function success = suspendServer(obj, serverID)
            responseBody = struct('suspend', 'null');
            addressExt = ['/servers/' serverID '/action'];
            [~, ~, ~] =...
                obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            
            % Need to set a time or loop limit
            [status, ~] = obj.getServerStatusID(serverID);
            while ~strcmp(status, 'SUSPENDED')
                pause(obj.waitingDelay);
                [status, ~] = obj.getServerStatusID(serverID);
            end
            success = true;
        end

        
        % -----
        function success = resumeServer(obj, serverID)
            responseBody = struct('resume', 'null');
            addressExt = ['/servers/' serverID '/action'];

            % Need to set a time or loop limit 
            [~, ~, ~] = obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            [status, ~] = obj.getServerStatusID(serverID);
            while ~strcmp(status, 'ACTIVE')
                pause(obj.waitingDelay);
                [status, ~] = obj.getServerStatusID(serverID);
            end
            success = true;
        end
        
        
        % -----
        % MAY BE INCORRECT IF THERE ARE NO SERVERS!!!!
        function [serverData, numServers] = getAllServersData(obj)
            addressExt = '/servers';
            [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
            serverData = loadjson(answer);
            numServers = size(serverData.servers, 2);
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
        function [status, powerState] = getServerStatusID(obj, id)
            details = obj.getServerDetailsID(id);
            status = details.server.status;
            powerState = details.server.(obj.powerStatePhrase);

        end

        
        % -----
        function [status, powerState] = getServerStatusName(obj, name)
            id = obj.serverIdFromName(name);
            details = obj.getServerDetailsID(id);
            status = details.server.status;
            powerState = details.server.(obj.powerStatePhrase);
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
            if obj.existsServerID(id)
                addressExt = ['/servers/' id];
                [~, answer, ~] = obj.issueComputeEndpointCommand('', {}, addressExt);
                details = loadjson(answer);
            else
                details = '';
            end
        end
    
        
        % -----
        function details = getServerDetailsName(obj, name)
            if obj.existsServerName(name)
                id = obj.serverIdFromName(name);
                details = obj.getServerDetailsID(id);
            else
                details = '';
            end
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
        function quota = getQuotas(obj)
                addressExt = ['/os-quota-sets/' obj.OS_TENANT_NAME];
                [~, answer, ~] = obj.issueComputeEndpointCommand('', {'-X GET '}, addressExt);
                quota = loadjson(answer);
        end

        
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
    
    methods (Access=protected)
%         % -----
%         function token = getToken(obj)
%             if ~isunix
%                 cmd = [fullfile(obj.curldir, 'curl -sS ') ...
%                        '-X POST ' obj.OS_IdentityEndpoint '/tokens '...
%                        '-H "Content-Type: application/json" '...
%                        '--key-type PEM '...
%                        ['--key ' obj.localKeyFile ' ']...
%                        '-d "{\"auth\": {\"tenantName\": \"' ...
%                        obj.OS_TENANT_NAME '\", '...
%                        '\"passwordCredentials\":  '...
%                        '{\"username\": \"' obj.OS_USERNAME '\", '...
%                         '\"password\": \"' obj.OS_PASSWORD '\"}'...
%                        '}}" '...
%                        ];
%             else
%                 % UNIX version not implemented yet
%                 %     cmd = ['./curl-7.46.0-win64-mingw/bin/curl --help'];
%             end
%             [~, answer] = system(cmd);
%             data = loadjson(answer);
%             token = data.access.token.id;
%         end
        
        
        % ------
        % data is a json string representing the data body
        % options is a cell array of option strings
        % address is the url to which to write
        function [result, answer, responseCode] = ...
                issueComputeEndpointCommand(obj, responseBody, options, addressExt)
            cmd = [fullfile(obj.curlDir, 'curl -sS ') ...
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
