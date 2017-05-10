% extractABIExpFeatures
function [status, cmdout] = ...
         extractABIExpFeatures(simID, ...
                               timeFilename, ...
                               voltageFilename, ...
                               stimulusFilename, ...
                               simDuration, ...        
                               stimStart, ...          
                               stimDuration, ...       
                               analysisStart, ...      
                               analysisDuration, ...   
                               featuresFilename, ...
                               runDir, ...
                               outDir ...
                               ) %#ok<*INUSD>
    pyStr = ['python ' ...
             fullfile(runDir, 'STGFeatExtr.py') ' ' ...
             simID ' ' ...
             timeFilename ' ' ...
             voltageFilename ' ' ...
             stimulusFilename ' ' ...
             num2str(simDuration) ' ' ...
             num2str(stimStart) ' ' ...
             num2str(stimDuration) ' ' ...
             num2str(analysisStart) ' ' ...
             num2str(analysisDuration) ' ' ...
             featuresFilename ' ' ...
             outDir ' ' ...
              '1> ' fullfile(outDir, 'FXout.txt') ...
             ' 2> ' fullfile(outDir, 'FXerr.txt')];
    [status, cmdout] = system(pyStr);
end