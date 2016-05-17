classdef CCCloudManagement < OSCloudManagement
    methods
        function obj = CCCloudManagement(cloudInfoFile)
            obj = obj@OSCloudManagement(cloudInfoFile);
        end

        function [serverName, serverId] = ...
                        createServerNoWait(obj, serverName, imageName,...
                                                flavorName, networkName)
        % Create a server but don't wait for it to finish building
            % At this level we reject if a server with that name already
            % exists, although OpenStack does allow servers with same name
            % and different IDs.
            if obj.existsServerName(serverName)
                error(['A server already exists with the name ' serverName '.'])
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
            networkId = obj.getNetworkIdFromName(networkName);
            responseBody = ['{"server":{'...
                            '"tenant_id":"' obj.OS_TENANT_NAME '",' ...
                            '"user_id":"'   obj.OS_USERNAME    '",' ...
                            '"key_name":"'  obj.OS_KEY_NAME    '",'...
                            '"name":"'      serverName         '",'...
                            '"imageRef":"'  imageRef           '",'...
                            '"flavorRef":"' flavorRef          '",'...
                            '"networks":['  '{"uuid":"' networkId '"}' ...
                            ']}}' ];
            addressExt = '/servers';
            [~, answer, ~] =...
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
        
        % -----
        function ipAddr = attachIpNewServer(obj, serverId)
            % Assume for CC that the floating IP is already allocated (we
            % had some problems ensuring one would be available)
            ipAddr = obj.allocateFloatingIp('');
            if isempty(ipAddr)
                error(['Could not allocate floating IP for ' serverId '.']);
            end

            if ~obj.associateFloatingIp(serverId, ipAddr)
                error(['Could not associate floating IP for ' ...
                       serverId ' using IP Address ' ipAddr '.']);
            end
        end
        
        % -----
        function tf = deleteServerId(obj, serverId)
        % true/success or false/failure
        % Does not deallocate any floating IP
            % Check for existence first. If doesn't exist return false.
            if ~obj.existsServerId(serverId)
                tf = false;
                return;
            end
            
            % Need to dissociate any associated floating IPs too so don't have
            % a floating IP leak but we don't deallocate them (CC)
            obj.disassociateFloatingIps(serverId);
 
            % Delete the server
            addressExt = ['/servers/' serverId];
            [~, ~, ~] =...
                obj.issueComputeEndpointCommand('', {'-X DELETE '}, addressExt);
            
            % Wait for successful termination
            % Watching for DELETED doesn't seem to work because the ability
            % to see DELETED goes away.
            % Later add a max number of checks before return false or cause
            % error. 
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
            if ~obj.existsServerId(serverId)
                name = '';
                status = '';
                ipAddr = {};
                return;
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
            
            % Grab the network / floating address pairs (if any) and return them
            ipAddr = {};
            if ~isfield(details.server, 'addresses')
                return;
            end
            allServerNetworks = obj.getServerNetworks(name);
            for i = 1:length(allServerNetworks)
                currentNetwork = allServerNetworks{i};
                currentNetworkFieldName = ...
                    OSCloudManagement.labelToFieldName(currentNetwork.label);
                if isfield(details.server.addresses, currentNetworkFieldName)
                    numAddresses =...
                        length(details.server.addresses.(currentNetworkFieldName));
                    for j = 1:numAddresses
                        currentNetworkAddress =...
                            details.server.addresses.(currentNetworkFieldName){j};
                        if isfield(currentNetworkAddress,...
                                   [obj.extAddressRoot '_0x3A_type'])
                            if strcmp(...
                                 currentNetworkAddress.([obj.extAddressRoot '_0x3A_type']),...
                                 'floating')
                                ipAddr = [ipAddr ...
                                    struct('network', currentNetwork.label,... 
                                           'address', currentNetworkAddress.addr)]; %#ok<AGROW>
                            end
                        end
                    end
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
            % NEED TO PROCESS ERRORS HERE
            % (not sure yet what to do)
            [~, answer] = system(cmd);
            data = loadjson(answer);
            token = data.access.token.id;
        end
        
    end
end
