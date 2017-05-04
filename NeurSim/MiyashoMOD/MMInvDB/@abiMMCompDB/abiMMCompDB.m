classdef abiFLIFCompDB < abiCompDB
    methods (Access=protected)
        setIpvsTableCmd(obj)
    end
    
    methods 
        function obj = abiFLIFCompDB(dataSourceName, databaseName, ...
                                     userName, password)
            obj = obj@abiCompDB(dataSourceName, databaseName, ...
                                userName, password);
            obj.setIpvsTableCmd(); % subclass--specific
        end

        %% addIPV 
        % This could be genericized someday but might lose clarity
        % (Of course) has to match the table creation command
        function ipvIndex = ...
                    addIPV(obj, expDataSetIndex, ...
                           tstop, tstep, taum, refrac, alpha, rM, ...
                           vRest, thresholdHeight, spikeHeight, p10, ...
                           stimCode, p12, stimulusStartTime, pulseWidth, ...
                           pulseCurrent, p16, p17, p18, p19, p20, p21)
            colnames = {'ipvIDX', 'expDataSetIDX', 'tstop', 'tstep', 'taum', 'refrac', ...
                        'alpha', 'rM', 'vRest', 'thresholdHeight', ...
                        'spikeHeight', 'rsrv', 'stimulusType', 'sC01', ...
                        'stimulusStartTime', 'pulseWidth', 'pulseCurrent', ...
                        'sC05', 'sC06', 'sC07', 'sC08', 'sC09', 'sC10'};
            % All this massaging needs to be designed/rewritten
            if isnan(p12)
                p12Str = 'NULL';
            else
                p12Str = num2str(p12);
            end
            if isnan(stimulusStartTime)
                stimulusStartTimeStr = 'NULL';
            else
                stimulusStartTimeStr = num2str(stimulusStartTime);
            end
            if isnan(pulseWidth)
                pulseWidthStr = 'NULL';
            else
                pulseWidthStr = num2str(pulseWidth);
            end
            if isnan(pulseCurrent)
                pulseCurrentStr = 'NULL';
            else
                pulseCurrentStr = num2str(pulseCurrent);
            end
            if isnan(p16)
                p16Str = 'NULL';
            else
                p16Str = num2str(p16);
            end
            if isnan(p17)
                p17Str = 'NULL';
            else
                p17Str = num2str(p17);
            end
            if isnan(p18)
                p18Str = 'NULL';
            else
                p18Str = num2str(p18);
            end
            if isnan(p19)
                p19Str = 'NULL';
            else
                p19Str = num2str(p19);
            end
            if isnan(p20)
                p20Str = 'NULL';
            else
                p20Str = num2str(p20);
            end
            if isnan(p21)
                p21Str = 'NULL';
            else
                p21Str = num2str(p21);
            end
            
            %%
            coldata = ...
               {num2str(expDataSetIndex), num2str(tstop), num2str(tstep), ...
                num2str(taum), num2str(refrac), ...
                num2str(alpha), num2str(rM), ...
                num2str(vRest), num2str(thresholdHeight), ...
                num2str(spikeHeight), p10, ...
                ['''' stimCode ''''], ...
                p12Str, stimulusStartTimeStr, ...
                pulseWidthStr, pulseCurrentStr, ...
                p16Str, p17Str, p18Str, p19Str, p20Str, p21Str};
            insertStr = ['insert into ipvs (' ...
                         strjoin(colnames, ', ') ') values(0, ' ...
                         strjoin(coldata, ', ') ')'];
            exec(obj.dbConn, insertStr);
            
            q = ('select ipvIDX from ipvs WHERE ipvIDX = @@IDENTITY');
            curs = exec(obj.dbConn, q);
            curs = fetch(curs);
            ipvIndex = curs.Data.ipvIDX;
            close(curs);
        end
    end
end