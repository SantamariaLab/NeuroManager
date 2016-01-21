% CloudBank
% A set of cloud instance data for use in working with a given cloud

classdef CloudBank < handle
    properties
        data;
    end
    
    methods
        function obj = CloudBank()
            obj.data = containers.Map();
        end
        
        function addInstance(obj, id, name, ipAddr, wkDir)
            instData.name = name;
            instData.ipAddr = ipAddr;
            instData.wkDir = wkDir;
            obj.data(id) = instData;
        end
        
        function ids = getInstanceIDs(obj)
            ids = keys(obj.data);
        end 
        
        function [name, ipAddr, wkDir] = getInfo(obj, id)
            if ~isKey(obj.data, id)
                name = '';
                ipAddr = '';
                wkDir = '';
            else
                name = obj.data(id).name;
                ipAddr = obj.data(id).ipAddr;
                wkDir = obj.data(id).wkDir;
            end
         
        end 
        
        
    end
end
