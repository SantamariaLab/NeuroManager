classdef OSCloudManagement < CloudManagement
    properties %(Access=protected)
        name;
        type;
        OS_TENANT_NAME;
        OS_IdentityEndpoint;
        OS_ComputeEndpoint;
        OS_NetworkEndpoint;
        OS_USERNAME;
        OS_PASSWORD;
        OS_KEY_NAME;        % on the cloud
        networks;
        powerStatePhrase;   % better terminology and handling necessary
        extAddressRoot;
        flavors;
        images;
        currentAuthToken;
        waitingDelay;       % seconds
        localKeyFile;       % on the NM host
        curldir;
    end
    methods(Abstract)
        getToken(obj)
    end
    methods
        function obj = OSCloudManagement(cloudInfoFile, localCurlDir, localKeyFile)
            % Pull in the infoFile (JSON format) and fill in the data
            % related to this class
            if ~exist(cloudInfoFile, 'file') == 2
                error(['Error: NeuroManager could not find the file '...
                       cloudInfoFile ' during configuration processing.']);
            end
            
            try
                cloudInfo = loadjson(cloudInfoFile);
            catch ME
                msg = ['Error processing %s. Possible syntax error.\n' ...
                       'Information given is: %s, %s.'];
                error(msg, cloudInfoFile, ME.identifier, ME.message);
            end
            obj.name = cloudInfo.resourceName;
            obj.type = cloudInfo.resourceType;
            obj.OS_IdentityEndpoint = cloudInfo.OS_IdentityEndpoint;
            obj.OS_ComputeEndpoint = cloudInfo.OS_ComputeEndpoint;
            obj.OS_NetworkEndpoint = cloudInfo.OS_NetworkEndpoint;
            obj.OS_TENANT_NAME = cloudInfo.OS_TENANT_NAME;
            obj.OS_USERNAME = cloudInfo.OS_USERNAME;
            obj.OS_PASSWORD = cloudInfo.OS_PASSWORD;
            obj.OS_KEY_NAME = cloudInfo.OS_KEY_NAME;
            obj.powerStatePhrase = cloudInfo.powerStatePhrase;
            obj.extAddressRoot = cloudInfo.extAddressRoot;
            
            if isfield(cloudInfo, 'networks')
                obj.networks = cloudInfo.networks;
            else
                error(['cloudInfoFile ' cloudInfoFile ' must specify at least one network.']);
            end
            
            if isfield(cloudInfo, 'flavors')
                obj.flavors = cloudInfo.flavors;
            else
                error(['cloudInfoFile ' cloudInfoFile ' must specify at least one flavor.']);
            end
            
            if isfield(cloudInfo, 'images')
                obj.images = cloudInfo.images;
            else
                error(['cloudInfoFile ' cloudInfoFile ' must specify at least one image.']);
            end

            obj.localKeyFile =  localKeyFile;
            obj.curldir = localCurlDir;
            obj.waitingDelay = 0.25;
            obj.currentAuthToken = obj.getToken();
        end

        % -----
        % Creates a single server and assigns it a floating ip address
        function [serverName, serverId] = ...
                            createServerWait(obj, serverName, imageName,...
                                                  flavorName, networkName)
            [createdServerName, serverId] = ...
                obj.createServerNoWait(serverName, imageName,...
                                            flavorName, networkName);
            if strcmp(createdServerName, serverName)
                obj.serverWaitTillReady(serverId);
            else
                error(['There was a problem creating server named ' ...
                       serverName ...
                       '.  Returned name did not match submitted name.']);
            end
        end

        % -----
        function serverList = ...
                 createMultipleServersNoWait(obj, numServers, ...
                        serverNameRoot, imageName, flavorName, networkName)
            serverList = {};
            if numServers <= 0
                error(['numServers must be greater than zero.'])
            end
            
            % Check request against quotas
            numAvailableSlots = obj.numAvailableServerSlots();
            if numAvailableSlots < numServers
                error(['There are not enough free server slots ' ...
                       'available under tenant ' obj.OS_TENANT_NAME ...
                       'to create ' numServers ' new ones' ...
                       '. Remove existing servers to form new ones.'])
            end

            for i = 1:numServers
                serverName = [serverNameRoot num2str(i, '%03u')]; 
                [serverName, serverId] = ...
                        createServerNoWait(obj, serverName, imageName,...
                                                flavorName, networkName);
                serverList = [serverList struct('name', serverName,...
                                                'id', serverId)]; %#ok<AGROW>
            end
        end
        
        % -----
        % Parallel deletion would be a little teeny bit faster but not
        % worth the effort at this point.
        function deleteMultipleServers(obj, serverList)
            for i = 1:length(serverList)
                obj.deleteServerId(serverList{i}.id);
            end
        end
        
        % -----
        function serverWaitTillReady(obj, serverId)
            % need to wait until get full creation 
            [status, powerState, progress] =...
                                    obj.getCreateServerProgress(serverId);
            while (strcmp(status, 'BUILD') && ~strcmp(progress, '100'))
                pause(obj.waitingDelay);
                [status, powerState, progress] =...
                                        obj.getCreateServerProgress(serverId);
            end            
            
            while powerState ~= 1
                pause(obj.waitingDelay);
                [~, powerState, ~] = obj.getCreateServerProgress(serverId);
            end
            
            % Wait till status is ACTIVE
            [status, ~, ~] = obj.getCreateServerProgress(serverId);
            while ~strcmp(status, 'ACTIVE')
                pause(obj.waitingDelay);
                [status, ~, ~] = obj.getCreateServerProgress(serverId);
            end
        end
        
        % -----
        function multipleServersWaitTillReady(obj, serverList)
            for i = 1:length(serverList)
                obj.serverWaitTillReady(serverList{i}.id)
            end
        end
        
        % -----
        function multipleNewServersAttachIp(obj, serverList)
            for i = 1:length(serverList)
                obj.attachIpNewServer(serverList{i}.id);
            end
        end
        
        % ------
        function details = getServerDetailsId(obj, id)
            if obj.existsServerId(id)
                addressExt = ['/servers/' id];
                [~, answer, ~] =...
                    obj.issueComputeEndpointCommand('', {}, addressExt);
                details = loadjson(answer);
            else
                details = '';
            end
        end
        
        % -----
        function details = getServerDetailsName(obj, name)
            if obj.existsServerName(name)
                id = obj.serverIdFromName(name);
                details = obj.getServerDetailsId(id);
            else
                details = '';
            end
        end
        
        % -----
        function images = listImages(obj)
            addressExt = '/images';
            [~, answer, ~] =...
                    obj.issueComputeEndpointCommand('', {}, addressExt);
            if isempty(strfind(answer, '404 Not Found'))
                images = loadjson(answer);
            else
                images = struct([]);
            end
        end
        
        % -----
        function flavors = listFlavors(obj)
            addressExt = '/flavors';
            [~, answer, ~] =...
                    obj.issueComputeEndpointCommand('', {}, addressExt);
            if isempty(strfind(answer, '404 Not Found'))
                flavors = loadjson(answer);
            else
                flavors = struct([]);
            end
        end
         
        % -----
        function networks = listNetworks(obj)
        % Get the networks currently associated with the tenant 
                addressExt = ['/os-networks'];
                [~, answer, ~] = ...
                obj.issueComputeEndpointCommand('', {'-X GET '}, addressExt);
            if isempty(strfind(answer, '404 Not Found'))
                networks = loadjson(answer);
            else
                networks = struct([]);
            end
        end
        
        % ----- 
        function servers = listServers(obj)
            addressExt = '/servers';
            [~, answer, ~] =...
                        obj.issueComputeEndpointCommand('', {}, addressExt);
            if isempty(strfind(answer, '404 Not Found'))
                servers = loadjson(answer);
            else
                servers = struct([]);
            end
        end

        % -----
        function keypairs = listKeyPairs(obj)
            addressExt = '/os-keypairs';
            [~, answer, ~] =...
                    obj.issueComputeEndpointCommand('', {}, addressExt);
            if isempty(strfind(answer, '404 Not Found'))
                keypairs = loadjson(answer);
            else
                keypairs = struct([]);
            end
        end
        
        % -----
        function numAvailableSlots = numAvailableServerSlots(obj)
            numAvailableSlots = 0;
            servers = obj.listServers();
            if ~isfield(servers, 'servers')
                return;
            end
            numServers = length(servers.servers);
            quotas = obj.getQuotas();
            if ~isfield(quotas, 'quota_set')
                return;
            end
            if ~isfield(quotas.quota_set, 'instances')
                return;
            end
            serverQuota = quotas.quota_set.instances;
            numAvailableSlots = serverQuota - numServers;
        end
        
        % -----
        function tf = existsServerId(obj, id)
            [serverData, numServers] = obj.getAllServersData();
            tf = false;
            if ~isfield(serverData, 'servers')
                return;
            end
            if isempty(serverData.servers)
                return;
            end
            for i = 1:numServers
                if strcmp(serverData.servers{1,i}.id, id)
                    tf = true;
                    break;
                end
            end
        end
        
        % -----
        function tf = existsServerName(obj, name)
            [serverData, numServers] = obj.getAllServersData();
            tf = false;
            if ~isfield(serverData, 'servers')
                return;
            end
            if isempty(serverData.servers)
                return;
            end
            for i = 1:numServers
                if strcmp(serverData.servers{1,i}.name, name)
                    tf = true;
                    break;
                end
            end
        end
        
        % -----
        function id = serverIdFromName(obj, name)
            id = '';
            [serverData, numServers] = obj.getAllServersData();
            if ~isfield(serverData, 'servers')
                return;
            end
            if isempty(serverData.servers)
                return;
            end
            for i = 1:numServers
                if strcmp(name, serverData.servers{1,i}.name)
                    id = serverData.servers{1,i}.id;
                    break;
                end
            end
        end
        
        % -----
        function name = serverNameFromId(obj, id)
            name = '';
            [serverData, numServers] = obj.getAllServersData();
            if ~isfield(serverData, 'servers')
                return;
            end
            if isempty(serverData.servers)
                return;
            end
            for i = 1:numServers
                if strcmp(id, serverData.servers{1,i}.id)
                    name = serverData.servers{1,i}.name;
                    break;
                end
            end
        end
        
        % -----
        function tf = existsImageName(obj, testName)
            tf = false;
            existingImages = obj.listImages();
            if ~isfield(existingImages, 'images')
                return;
            end
            if isempty(existingImages.images)
                return;
            end
            for i = 1:length(existingImages.images)
                if strcmp(existingImages.images{i}.name, testName)
                    tf = true;
                    break;
                end
            end
        end
        
        % -----
        function tf = existsFlavorName(obj, testName)
            tf = false;
            existingFlavors = obj.listFlavors();
            if ~isfield(existingFlavors, 'flavors')
                return;
            end
            if isempty(existingFlavors.flavors)
                return;
            end
            for i = 1:length(existingFlavors.flavors)
                if strcmp(existingFlavors.flavors{i}.name, testName)
                    tf = true;
                    break;
                end
            end
        end
        
        % -----
        function tf = existsNetworkName(obj, testName)
            tf = false;
            existingNetworks = obj.listNetworks();
            if ~isfield(existingNetworks, 'networks')
                return;
            end
            if isempty(existingNetworks.networks)
                return;
            end
            for i = 1:length(existingNetworks.networks)
                if strcmp(existingNetworks.networks{i}.label, testName)
                    tf = true;
                    break;
                end
            end
        end
        
        % -----
        function tf = existsKeyPairName(obj, testName)
            tf = false;
            existingKeyPairs = obj.listKeyPairs();
            if isempty(existingKeyPairs.keypairs)
                return;
            end
            for i = 1:length(existingKeyPairs.keypairs)
                if strcmp(existingKeyPairs.keypairs{i}.keypair.name, testName)
                    tf = true;
                    break;
                end
            end
        end
        
        % -----
        function quota = getQuotas(obj)
                addressExt = ['/os-quota-sets/' obj.OS_TENANT_NAME];
                [~, answer, ~] = ...
                    obj.issueComputeEndpointCommand('', {'-X GET '}, addressExt);
                try
                    quota = loadjson(answer);
                catch ME
                    msg = ['Quota request error.\n' ...
                           'Information given is: %s, %s.'];
                    error(msg, ME.identifier, ME.message);
                end
        end
        
        %============================================
        % -----
        function ref = getFlavorRef(obj, name)
        % DEPENDS ON FLAVORS EXISTING WHEN THE MANAGEMENT OBJECT WAS CREATED.
            ref = '';
            for i=1:length(obj.flavors)
                if strcmp(obj.flavors{i}.name, name)
                    ref = obj.flavors{i}.reference;
                    break;
                end
            end
        end
        
        % -----
        function ref = getImageRef(obj, name)
        % DEPENDS ON IMAGES EXISTING WHEN THE MANAGEMENT OBJECT WAS CREATED.
            ref = '';
            for i=1:length(obj.images)
                if strcmp(obj.images{i}.name, name)
                    ref = obj.images{i}.thisImageRef;
                    break;
                end
            end
        end

        % -----
        function id = getNetworkIdFromName(obj, name)
        % DEPENDS ON NETWORKS EXISTING WHEN THE MANAGEMENT OBJECT WAS CREATED.
            id = '';
            for i=1:length(obj.networks)
                if strcmp(obj.networks{i}.name, name)
                    id = obj.networks{i}.id;
                    break;
                end
            end
        end

        % -----
        function [status, powerState, progress] =...
                            getCreateServerProgress(obj, serverId)
            addressExt = ['/servers/' serverId];
            [~, answer, ~] =...
                obj.issueComputeEndpointCommand('', {'-X GET '}, addressExt);
            try
                info = loadjson(answer);
            catch ME
                % Via a race condition seen using Rackspace which I
                % haven't been able to replicate
                disp(['ME.identifier ' ME.identifier]);
            end
            status = info.server.status;
            powerState = info.server.(obj.powerStatePhrase);
            progress = info.server.progress;
        end
        
        % -----
        function [serverData, numServers] = getAllServersData(obj)
            addressExt = '/servers';
            [~, answer, ~] = ...
                    obj.issueComputeEndpointCommand('', {}, addressExt);
            try
                serverData = loadjson(answer);
            catch 
                serverData = {};
                numServers = 0;
                return;
            end
            if isfield(serverData, 'servers')
                numServers = length(serverData.servers);
            else
                numServers = 0;
            end
        end
        
        % -----
        function tf = existsFloatingIP(obj, ipId)
            tf = false;
            floatingIPs = obj.listFloatingIPs();
            if isfield(floatingIPs, 'floating_ips')
                numIps = length(floatingIPs.floating_ips);
            else 
                return;
            end
            for i = 1:numIps
                if strcmp(floatingIPs.floating_ips{1,i}.id, ipId)
                    tf = true;
                    break;
                end
            end
        end
        
        % -----
        function floatingIPs = listFloatingIps(obj)
            addressExt = '/os-floating-ips';
            [~, answer, ~] =...
                        obj.issueComputeEndpointCommand('', {}, addressExt);
            if ~isempty(answer)
                floatingIPs = loadjson(answer);
            else 
                floatingIPs = {};
            end
        end
        
        % -----
        function ipIds = listFloatingIpsServer(obj, serverId)
        % List the floating IPs associated with a specific server
        % For CC "there can be only one" but we use a list anyway
            ipIds = {};
            floatingIps = obj.listFloatingIps();
            if ~isfield(floatingIps, 'floating_ips')
                return;
            end
            for i=1:length(floatingIps.floating_ips)
                if strcmp(floatingIps.floating_ips{i}.instance_id, serverId)
                    id = floatingIps.floating_ips{i}.id;
                    ipIds = [ipIds id];  %#ok<AGROW>
                end
            end
        end

        % -----
        function ips = listServerIps(obj, serverId)
        % Does not identify floating or fixed
            addressExt = ['/servers/' serverId '/ips'];
            [~, answer, ~] =...
                        obj.issueComputeEndpointCommand('', {}, addressExt);
            if ~isempty(answer)
                ips = loadjson(answer);
            else 
                ips = {};
            end
        end

        % -----
        function ip = allocateFloatingIp(obj, pool)
        % need to check for allocation restriction
        % empty pool string means fetch an IP that is already allocated but
        % not associated with a server (if such exists).
            if ~isempty(pool)
                responseBodyStruct = struct('pool', pool); 
                responseBody = savejson('', responseBodyStruct);
                responseBody = responseBody(~isspace(responseBody)); % Remove whitespace
                addressExt = '/os-floating-ips';
                [~, answer, ~] =...
                    obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
                try
                    ipData = loadjson(answer);
                catch ME
                    error(['Cloud API command failed. Information provided is: ' ...
                           answer]);
                end
                if isfield(ipData, 'floating_ip')
                    ip = ipData.floating_ip.ip;
                else
                    ip = '';
                end
            else
                ip = '';
                floatingIps = obj.listFloatingIps();
                if ~isfield(floatingIps, 'floating_ips')
                    return;
                end
                for i=1:length(floatingIps.floating_ips)
                    ipData = floatingIps.floating_ips{i};
                    if isempty(ipData.instance_id)
                        ip = ipData.ip;
                        break;
                    end
                end
            end
        end
        
        % -----
        function tf = deallocateFloatingIp(obj, ipId)
            addressExt = ['/os-floating-ips/' ipId];
            [~, ~, ~] =...
                obj.issueComputeEndpointCommand('', {'-X DELETE '}, addressExt);
            
            % Verify (need delay?)
            if obj.existsFloatingIp(ipId)
                tf = false;
            else
                tf = true;
            end
        end
        
        % -----
        function addr = floatingIpAddrFromId(obj, id)
        % Return the address of a floating IP from its ID.  Returns empty
        % string otherwise.
            addr = '';
            floatingIps = obj.listFloatingIps();
            if ~isfield(floatingIps, 'floating_ips')
                return;
            end
            for i = 1:length(floatingIps.floating_ips)
                if strcmp(floatingIps.floating_ips{i}.id, id)
                    addr = floatingIps.floating_ips{i}.ip;
                    break;
                end
            end
        end

        % -----
        function id = floatingIpIdFromAddr(obj, addr)
        % Return the address of a floating IP from its ID.  Returns empty
        % string otherwise.
            id = '';
            floatingIps = obj.listFloatingIps();
            if ~isfield(floatingIps, 'floating_ips')
                return;
            end
            for i = 1:length(floatingIps.floating_ips)
                if strcmp(floatingIps.floating_ips{i}.ip, addr)
                    id = floatingIps.floating_ips{i}.id;
                    break;
                end
            end
        end
        
        % -----
        function tf = associateFloatingIp(obj, serverId, ipAddr)
        % ASSUMES ONLY ONE NETWORK
            responseBodyStruct = struct('addFloatingIp', struct('address', ipAddr));
            responseBody = savejson('', responseBodyStruct);
            responseBody = responseBody(~isspace(responseBody)); % Remove whitespace
            addressExt = ['/servers/' serverId '/action'];
            [~, ~, ~] =...
                obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            [~, ~, ipAddrActual] = obj.getServerDataId(serverId);
            if isempty(ipAddrActual)
                tf = false;
                return;
            end
            if ~isfield(ipAddrActual{1}, 'address')
                tf = false;
                return;
            end
            if strcmp(ipAddr, ipAddrActual{1}.address)
                tf = true;
            else
                tf = false;
            end
        end
        
        % -----
        function disassociateFloatingIps(obj, serverId)
        % Does not deallocate
            floatingIpIds = obj.listFloatingIpsServer(serverId);
            for i=1:length(floatingIpIds)
                % Disassociate each 
                responseBodyStruct = struct('removeFloatingIp',...
                    struct('address',...  
                           obj.floatingIpAddrFromId(floatingIpIds{i})));
                responseBody = savejson('', responseBodyStruct);
                responseBody = responseBody(~isspace(responseBody)); % Remove whitespace
                addressExt = ['/servers/' serverId '/action'];
                [~, ~, ~] =...
                    obj.issueComputeEndpointCommand(responseBody, {}, addressExt);
            end
        end
        
        % -----
        function [status, powerState] = getServerStatusId(obj, id)
            details = obj.getServerDetailsId(id);
            if isfield(details.server, 'status')
                status = details.server.status;
            else
                status = 'UNKNOWN';
            end
            if isfield(details.server, obj.powerStatePhrase);
                powerState = details.server.(obj.powerStatePhrase);
            else
                powerState = 'UNKNOWN';
            end
        end
        
        % -----
        function [status, powerState] = getServerStatusName(obj, name)
            id = obj.serverIdFromName(name);
            [status, powerState] = obj.getServerStatusId(id);
        end
        
        % -----
        % Get the networks attached directly to the named server
        function serverNetworks = getServerNetworks(obj, name)
            serverNetworks = {};
            details = obj.getServerDetailsName(name);
            if isempty(details)
                return;
            end
            possibleNetworks = obj.listNetworks();
            if isempty(possibleNetworks)
                return;
            end
            numPossibleNetworks = length(possibleNetworks.networks);
            for i=1:numPossibleNetworks
                currentNetworkLabel = possibleNetworks.networks{i}.label;
                networkFieldName = ...
                    OSCloudManagement.labelToFieldName(currentNetworkLabel);
                if isfield(details.server.addresses, networkFieldName)
                    addlNetworkLabel = possibleNetworks.networks{i}.label;
                    addlNetworkId = possibleNetworks.networks{i}.id;
                    serverNetworks = [serverNetworks ...
                        struct('label', addlNetworkLabel, ...
                               'id',    addlNetworkId)]; %#ok<AGROW>
                end
            end
        end
        
        % -----
        function extAddressRoot = getExtAddressRoot(obj)
            extAddressRoot = obj.extAddressRoot;
        end
        
    end
    methods (Static)
        % These may not be general conversions, but field names don't have
        % dashes, so there are conversions implied in the OS API
        function fn = labelToFieldName(label)
             fn = strrep(label, '-', '_0x2D_');
        end
        
        function label = fieldNameToLabel(fn)
             label = strrep(fn, '_0x2D_', '-');
        end
    end
    
    methods (Access=protected)
        
        % ------
        % data is a json string representing the data body
        % options is a cell array of option strings
        % address is the url to which to write
        % Works but needs a little more elegant form
        function [result, answer, responseCode] = ...
                issueComputeEndpointCommand(obj, responseBody, options, addressExt)
            cmd = [fullfile(obj.curldir, 'curl -sS ') ...
                   '-H "X-Auth-Token: ' obj.currentAuthToken '" '...
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
                data = ['"' strrep(responseBody, '"', '\"') '"'];
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
            while strfind(responseCode, '401')
                % Remove the disp when finally verify that this is working
                disp('>>>> Refreshing Compute token. <<<<')
                obj.currentAuthToken = obj.getToken();
                cmd = [fullfile(obj.curldir, 'curl -sS ') ...
                       '-H "X-Auth-Token: ' obj.currentAuthToken '" '...
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
                    data = ['"' strrep(responseBody, '"', '\"') '"'];
                    cmd = [cmd ' -d ' data ' ']; %#ok<AGROW>
                end
                address = [obj.OS_ComputeEndpoint addressExt];
                cmd = [cmd address]; %#ok<AGROW>
                [result, rawAnswer] = system(cmd);
                responseCode = regexprep(rawAnswer, parseRegExp, '$2');
            end
            answer = regexprep(rawAnswer, parseRegExp, '$1');
        end
    end
end
