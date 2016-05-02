classdef WispSet < handle
    properties
        cloud;
        wisps;
    end
    methods
        function obj=WispSet(cloudInfoFile, imageName, flavorName)
            % Pull in the infoFile (JSON format) and fill in the data
            % related to this class
            if ~exist(cloudInfoFile, 'file') == 2
                error(['Error: NeuroManager could not find the file '...
                       cloudInfoFile ' during configuration processing.']);
            end
            
            % Later choose between cloud types here
            obj.cloud = CCCLoud(cloudInfoFile);
            try
                cloudInfoData = loadjson(cloudInfoFile);
            catch ME
                msg = ['Error processing %s. Possible syntax error.\n' ...
                       'Information given is: %s, %s.'];
                error(msg, infoFile, ME.identifier, ME.message);
            end
                
                         
        end
        
        % Add num wisps to the wisp set
        % This will allow adding wisps on the fly
        function add(obj, num)
        end
        
        % Remove some of the wisps (not implemented yet)
%         function remove(obj, num)
%         end
        
        % Remove all instances from the cloud and from the set completely.
        % Does not delete the WispSet object
        function removeAll(obj)
        end
    end
end