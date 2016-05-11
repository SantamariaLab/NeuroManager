classdef ClusterConfig  < MachineConfig
    properties
        queues;
        queueString; % queue
        
        parEnvStr;
        resourceStr;
        numNodes;
        wallClockTime;
    end
    
    methods
        function obj = ClusterConfig(infoFile)
            obj = obj@MachineConfig(infoFile);
            
            % Cluster-specific details
            if isfield(obj.imageData, 'fsUserName')
                obj.fsUserName = obj.imageData.fsUserName;
            else
                error(['Infofile ' infoFile ' must specify fsUserName.']);
            end
            
            if isfield(obj.imageData, 'fsPassword')
                obj.fsPassword = obj.imageData.fsPassword;
            else
                error(['Infofile ' infoFile ' must specify fsPassword.']);
            end
            
            if isfield(obj.imageData, 'jsUserName')
                obj.jsUserName = obj.imageData.jsUserName;
            else
                error(['Infofile ' infoFile ' must specify jsUserName.']);
            end
            
            if isfield(obj.imageData, 'jsPassword')
                obj.jsPassword = obj.imageData.jsPassword;
            else
                error(['Infofile ' infoFile ' must specify jsPassword.']);
            end
            
            if isfield(obj.infoData, 'queues')
                obj.queues = obj.infoData.queues;
            else
                error(['Infofile ' infoFile ' must specify at least one queue.']);
            end
            
            % --
            if isfield(obj.imageData, 'fsIpAddress')
                obj.fsIpAddress = obj.imageData.fsIpAddress;
            else
                error(['Imagefile ' imageFile ' must specify fsIpAddress.']);
            end
            
            if isfield(obj.imageData, 'jsIpAddress')
                obj.jsIpAddress = obj.imageData.jsIpAddress;
            else
                error(['Imagefile ' imageFile ' must specify jsIpAddress.']);
            end
        end
    end
    
end