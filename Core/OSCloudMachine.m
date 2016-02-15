% OSCloudMachine
% Builds an OSCloudMachine object using a currently existing instance or by
% creating a new one. If name exists, uses that instance; if not makes a
% new one with that name; if no name or empty name supplied, then uses
% autoNameRoot to make a new one with incremental numbering.
%
classdef OSCloudMachine < OSCloud
    properties
        InstancePublicIP;
        serverID;
        serverName;
        serverIpAddr;
        autoNameRoot = 'OSCloud';
    end
    
    methods
        function obj = OSCloudMachine(name)
            if nargin==0
                name = '';
            end
            obj = obj@OSCloud();
            % Create the machine if necessary and get it into running state
            % for NeuroManager use
            if isempty(name)
                nameNum = 0;
                while isempty(name)
                    nameNum = nameNum + 1;
                    name = [obj.autoNameRoot '-' num2str(nameNum, '%06u')];
                    [name, serverID, ipAddr] = obj.createServer(name);
                end
                obj.serverName = name;
                obj.serverID = serverID;
                obj.serverIpAddr = ipAddr;
            else % ensure it exists and is ready to go
                % Later check to be sure it has proper flavor and image
                if obj.existsServerName(name)
                    obj.serverName = name;
                    obj.serverID = obj.serverIdFromName(name);
                    [~, status, ipAddr] = obj.getData();
                    obj.serverIpAddr = ipAddr;
                    % We do not yet handle other states
                    if strcmp(status, 'SUSPENDED')
                        obj.resume();
                    end
                else
                    [name, serverID, ipAddr] = obj.createServer(name);
                    obj.serverName = name;
                    obj.serverID = serverID;
                    obj.serverIpAddr = ipAddr;
                end
            end
        end
        
        % -----
        function [id, name, status, ipAddr] = getData(obj)
            [name, status, ipAddr] = obj.getServerData(obj.serverID);
            id = obj.serverID;
        end
        
        % -----
        function details = getDetails(obj)
            details = obj.getServerDetailsID(obj.serverID);
        end
        
        % -----
        function id = getID(obj)
            id = obj.serverID;
        end
        
        % -----
        function [status, powerState] = getStatus(obj)
            [status, powerState] = obj.getServerStatusID(obj.serverID);
        end
        
        % -----
        function success = suspend(obj)
            success = obj.suspendServer(obj.serverID);
        end
        
        % -----
        function success = resume(obj)
            success = obj.resumeServer(obj.serverID);
        end
        
        % -----
        function tf = delete(obj)
            tf = obj.deleteServer(obj.serverID);
        end
    end    
end
