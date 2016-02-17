% OSCloudInstance
% Builds an OSCloudInstance object using a currently existing instance or by
% creating a new one. If name exists, uses that instance; if not makes a
% new one with that name; if no name or empty name supplied, then uses
% autoNameRoot to make a new one with incremental numbering.
%
classdef OSCloudInstance < OSCloud
    properties
        InstancePublicIP;
        instanceID;
        instanceName;
        instanceIpAddr;
        autoNameRoot = 'OSCloud';
    end
    
    methods
        function obj = OSCloudInstance(name)
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
                    [name, instanceID, ipAddr] = obj.createServer(name);
                end
                obj.instanceName = name;
                obj.instanceID = instanceID;
                obj.instanceIpAddr = ipAddr;
            else % ensure it exists and is ready to go
                % Later check to be sure it has proper flavor and image
                if obj.existsServerName(name)
                    obj.instanceName = name;
                    obj.instanceID = obj.serverIdFromName(name);
                    [~, status, ipAddr] = obj.getData();
                    obj.instanceIpAddr = ipAddr;
                    % We do not yet handle other states
                    if strcmp(status, 'SUSPENDED')
                        obj.resume();
                    end
                else
                    [name, instanceID, ipAddr] = obj.createServer(name);
                    obj.instanceName = name;
                    obj.instanceID = instanceID;
                    obj.instanceIpAddr = ipAddr;
                end
            end
        end
        
        % -----
        function [id, name, status, ipAddr] = getData(obj)
            [name, status, ipAddr] = obj.getServerData(obj.instanceID);
            id = obj.instanceID;
        end
        
        % -----
        function details = getDetails(obj)
            details = obj.getServerDetailsID(obj.instanceID);
        end
        
        % -----
        function id = getID(obj)
            id = obj.instanceID;
        end
        
        % -----
        function [status, powerState] = getStatus(obj)
            [status, powerState] = obj.getServerStatusID(obj.instanceID);
        end
        
        % -----
        function success = suspend(obj)
            success = obj.suspendServer(obj.instanceID);
        end
        
        % -----
        function success = resume(obj)
            success = obj.resumeServer(obj.instanceID);
        end
        
        % -----
        function tf = terminate(obj)
            tf = obj.deleteServer(obj.instanceID);
        end
    end    
end
