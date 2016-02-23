% InstanceData.m
classdef InstanceData < handle
    properties
        imageName;
        imageRef;
        hostKeyFingerprint;
        cloudName;
        flavorName;
        flavorRef;
        keyPairName;
        keyPairRef;
    end
    
    methods
        function obj = InstanceData(dataFilePath)
            if ~exist(dataFilePath, 'file')==2
                error(['NeuroManager error: user data file ' ...
                       dataFile ' not found.']);
            end
            instanceData = ini2struct(dataFilePath);
            
            validsectionnames = {'image', 'cloud', 'flavor', 'keypair'};
            for sname = validsectionnames
                if ~isfield(instanceData, sname{1})
                    error('iniFile:missingSection', ...
                          ['NeuroManager error: [' sname{1} '] section is missing from:\n' ...
                          strrep(dataFilePath, '\', '\\') ...
                          '\n Sections found were: %s'],...
                          strjoin(fieldnames(instanceData), ', '));
                end
            end
            obj.name = instanceData.image.name;
            obj.cloud = instanceData.image.cloud;
            obj.hostKeyFingerprint = instanceData.image.hostkeyfingerprint;
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function cloud = getCloud(obj)
            cloud = obj.cloud;
        end
        
        function fingerprint = getFingerprint(obj)
            fingerprint = obj.hostKeyFingerprint;
        end
    end
end
