% Concerned with building a SimSpec file automatically.
classdef SimSpecFile < handle
    properties
        path;
        simSetID;
        filename;
        simType;
        fullPath;
        paramNameStr;
    end
    methods
        function obj = SimSpecFile(path, simSetID, filename, simType)
            obj.path = path;
            obj.simSetID = simSetID;
            obj.filename = filename;
            obj.simType = simType;
            obj.fullPath = fullfile(obj.path, filename)
%             if exist(obj.fullPath, 'file') == 2
%                 error(['SimSpec file ' obj.fullPath ' already exists.']);
%             end
            obj.paramNameStr = ['p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 ' ...
                                'p11 p12 p13 p14 p15 p16 p17 p18 p19 p20 p21'];
        end
        
        function InsertHeader(obj)
            % Create the header
            [fh, errmsg] = fopen(obj.fullPath, 'w');
            fprintf(fh, '%s %s %s\n', 'SIMSETDEF',  obj.simSetID, obj.simType);
            fprintf(fh, '%s\n', ['% Constructed automatically by the ' ...
                                     'SimSpec class']);
            fprintf(fh, '%s\n', '% DO NOT EDIT.  WILL BE OVERWRITTEN!');
            fprintf(fh, '%s\n', ['% SIMID(N)      ' obj.paramNameStr]);
%             fprintf(f, '%s\n', ['%                tstop  tstep      taum ' ...
%                                 'refrac  alpha   rM    vRest tHgt spkHgt rsrv ' ...
%                                 'Stim sC01  sC02  sC03  sC04  sC05  sC06  ' ...
%                                 'sC07  sC08  sC09  sC10']);
            fclose(fh);
        end
        
        function addPoint(obj, NotificationFlag, simID, varargin)
            if NotificationFlag
                nf = 'N';
            else
                nf = ' ';
            end
            fh = fopen(obj.fullPath, 'a');
            numParams = length(varargin);
            paramStrList = cell(numParams, 1);
            for i=1:numParams
                p = varargin{i};
                if islogical(p)
                    if(p)
                        paramStrList{i} = '1';
                    else
                        paramStrList{i} = '0';
                    end
                elseif ischar(p)
                    paramStrList{i} = p;
                elseif isempty(p)
                    if iscell(p)
                        paramStrList{i} = '{}';
                    else
                        paramStrList{i} = '[]';
                    end
                elseif isnumeric(p)
                    paramStrList{i} = num2str(p);
                elseif isnan(p)
                    paramStrList{i} = 'NaN';
                else
                    paramStrList{i} = 'NULL';
                end
            end
            
            fprintf(fh, '%s%s %s ', 'SIMDEF', nf, simID);
            fprintf(fh, ' %s', paramStrList{:});
            fprintf(fh, '\n');
            fclose(fh);
        end
%             num2str(tstep,          '%010.6f'), ...
%             num2str(points{j,3},    '%6.1f'), ... taum
%             num2str(refrac,         '%6.1f'), ...
%             num2str(points{j,1},    '%6.2f'), ...
%             num2str(rM,             '%8.2f'), ...
%             num2str(vRest,          '%6.1f'), ...
%             num2str(points{j,2},    '%6.1f'), ...
%             num2str(spikeHeight,    '%6.1f'), ...
%             p10Str, stimCode, p12Str, ...
%             stimulusStartTimeStr, ...
%             pulseWidthStr, pulseCurrentStr, ...
%             p16Str, p17Str, p18Str, p19Str, p20Str, p21Str);

%             fprintf(fh, ['%s%s %s ' ...
%             '%s %s %s  %s     %s    %s %s %s %s %s ' ...
%             '%s   %s     %s     %s     %s     %s     %s   ' ...
%             '  %s     %s     %s     %s\n'], ...
%            'SIMDEF', nf, simID,...
%             num2str(tstop,          '%6.1f'), ...
%             num2str(tstep,          '%010.6f'), ...
%             num2str(points{j,3},    '%6.1f'), ... taum
%             num2str(refrac,         '%6.1f'), ...
%             num2str(points{j,1},    '%6.2f'), ...
%             num2str(rM,             '%8.2f'), ...
%             num2str(vRest,          '%6.1f'), ...
%             num2str(points{j,2},    '%6.1f'), ...
%             num2str(spikeHeight,    '%6.1f'), ...
%             p10Str, stimCode, p12Str, ...
%             stimulusStartTimeStr, ...
%             pulseWidthStr, pulseCurrentStr, ...
%             p16Str, p17Str, p18Str, p19Str, p20Str, p21Str);
            
            
    end
end
