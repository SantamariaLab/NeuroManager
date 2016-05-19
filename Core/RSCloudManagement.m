classdef RSCloudManagement < OSCloudManagement
    methods
        function obj = RSCloudManagement(cloudInfoFile, ...
                                         localCurlDir, localKeyFile)
            obj = obj@OSCloudManagement(cloudInfoFile, ...
                                        localCurlDir, localKeyFile);
        end

        
        % -----
        function [serverName, serverId] = ...
                        createServerNoWait(obj, serverName, imageName, ...
                                                flavorName, networkName)
        % Creates a single server and assigns it a floating ip address
            % At this level we reject if a server with that name already
            % exists, although OpenStack does allow servers with same name
            % and different IDs.
            if obj.existsServerName(serverName)
                serverName = ''; serverId = ''; 
                return;
            end
            
            % Check request against quotas
            numAvailableSlots = obj.numAvailableServerSlots();
            if numAvailableSlots < 1
                error(['There are no free server slots available ' ...
                       'under tenant ' obj.OS_TENANT_NAME ...
                       '. Remove existing servers to form new ones.'])
            end

            imageRef = obj.getImageRef(imageName);
            flavorRef = obj.getFlavorRef(flavorName);
            if ~isempty(networkName)
                networkId = obj.getNetworkIdFromName(networkName);
                responseBody = ['{"server":{'...
                                '"tenant_id":"' obj.OS_TENANT_NAME '",' ...
                                '"user_id":"'   obj.OS_USERNAME    '",' ...
                                '"key_name":"'  obj.OS_KEY_NAME    '",'...
                                '"name":"'      serverName     '",'...
                                '"imageRef":"'  imageRef           '",'...
                                '"flavorRef":"' flavorRef          '",'...
                                '"networks":['  '{"uuid":"' networkId '"}' ...
                                ']}}' ];
            else
                responseBody = ['{"server":{'...
                                '"tenant_id":"' obj.OS_TENANT_NAME '",' ...
                                '"user_id":"'   obj.OS_USERNAME    '",' ...
                                '"key_name":"'  obj.OS_KEY_NAME    '",'...
                                '"name":"'      serverName     '",'...
                                '"imageRef":"'  imageRef           '",'...
                                '"flavorRef":"' flavorRef          '"'...
                                '}}' ];
            end
            addressExt = '/servers';
            [~, answer, ~] = ...
                obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            server = loadjson(answer);
            if isfield(server, 'server')
                serverId = server.server.id;
            else
                error(['Cloud API command failed. Information provided is: ' ...
                       answer]);
            end
            [serverName, ~, ~] = obj.getServerDataId(serverId);
        end

        function ipAddr = attachIpNewServer(obj, serverId)
            % Nothing to do for Rackspace but fetch the already-assigned Ip
            [~, ~, ipAddrArray] = obj.getServerDataId(serverId);
            ipAddr = ipAddrArray{1}.address;
        end
        
        % -----
        function tf = deleteServerId(obj, serverId)
        % true/success or false/failure
            % Check for existence first. If doesn't exist return false.
            if ~obj.existsServerId(serverId)
                tf = false;
                return;
            end
            
            % Rackspace has no need to remove any associated floating IPs 
            % (nothing to do)

            % Delete the server
            addressExt = ['/servers/' serverId];
            [~, ~, ~] =...
                obj.issueComputeEndpointCommand('', {'-X DELETE '}, addressExt);
            
            % Wait for successful termination
            % Watching for DELETED doesn't seem to work because the ability
            % to see DELETED goes away.
            % Later add a max number of checks before return false.
            while obj.existsServerId(serverId)
                pause(obj.waitingDelay);
            end
            tf = true;
        end

        % -----
        function [name, status, ipAddr] = getServerDataId(obj, serverId)
        % ipaddr is a cell array of network/ipaddr pairs. Actually IPs are
        % associated with ports but we are trying to simplify to
        % NeuroManager needs. (a little overkill but leave it for now)
        % Rackspace default has no network except public so rather than
        % increase costs by adding a network for similarity with Chameleon,
        % we just throw the public in for now.
            if ~obj.existsServerId(serverId)
                name = '';
                status = '';
                ipAddr = {};
                return
            end
            details = obj.getServerDetailsId(serverId);
            if ~isfield(details, 'server')
                name = ''; %#ok<*NASGU>
                status = '';
                ipAddr = {};
                return;
            end
            name = details.server.name;
            status = details.server.status;
            ipAddr = {struct('network', 'public', ...
                             'address', details.server.accessIPv4)};
        end
        
        % -----
        function token = getToken(obj)
            if ~isunix
                cmd = [fullfile(obj.curldir, 'curl -sS ') ...
                       '-X POST ' obj.OS_IdentityEndpoint '/tokens '...
                       '-H "Content-Type: application/json" '...
                       '-d "{\"auth\": {\"RAX-KSKEY:apiKeyCredentials\":  '...
                       '{\"username\": \"' obj.OS_USERNAME '\", '...
                        '\"apiKey\": \"' obj.OS_PASSWORD '\"}'...
                       '}}" '...
                       ];
%                        '--key-type PEM '...
%                        ['--key ' obj.localKeyFile ' ']...
            else
                % UNIX version not implemented yet
                %     cmd = ['./curl-7.46.0-win64-mingw/bin/curl --help'];
            end
            % NEED TO PROCESS ERRORS HERE
            % (not sure yet what to do)
            [~, answer] = system(cmd);
            data = loadjson(answer);
            token = data.access.token.id;
        end
    end
end
