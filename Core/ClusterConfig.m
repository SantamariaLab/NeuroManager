classdef ClusterConfig  < MachineConfig
    properties
        queues;
%         id; % queue
%         extension; % queue
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
            if isfield(obj.infoData, 'fsUserName')
                obj.fsUserName = obj.infoData.fsUserName;
            else
                error(['Infofile ' infoFile ' must specify fsUserName.']);
            end
            
            if isfield(obj.infoData, 'fsPassword')
                obj.fsPassword = obj.infoData.fsPassword;
            else
                error(['Infofile ' infoFile ' must specify fsPassword.']);
            end
            
            if isfield(obj.infoData, 'jsUserName')
                obj.jsUserName = obj.infoData.jsUserName;
            else
                error(['Infofile ' infoFile ' must specify jsUserName.']);
            end
            
            if isfield(obj.infoData, 'jsPassword')
                obj.jsPassword = obj.infoData.jsPassword;
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