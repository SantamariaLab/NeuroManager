% MLVersion
% See https://en.wikipedia.org/wiki/MATLAB
% and http://www.mathworks.com/help/matlab/release-notes.html#Compatibility_Summary
% This is currently a simple previous-or-same-is-compatible setup.
classdef MLVersion
    properties
        releaseName;
        releaseNum;
    end
    methods
        function t = MLVersion(str, num)
            t.releaseName = str;
            t.releaseNum = num;
        end
        
        function tf = isCompatible(ver, testVer)
            if ver.releaseNum >= testVer.releaseNum
                tf = true;
            else
                tf = false;
            end
        end
    end
    
    enumeration
        % Type name                         
        MATLAB_7_12                     ('2011a', 25)
        MATLAB_7_13                     ('2011b', 26)
        MATLAB_7_14                     ('2012a', 27)
        MATLAB_8                        ('2012b', 28)
        MATLAB_8_1                      ('2013a', 29)
        MATLAB_8_2                      ('2013b', 30)
        MATLAB_8_3                      ('2014a', 31)
        MATLAB_8_4                      ('2014b', 32)
        MATLAB_8_5                      ('2015a', 33)
        MATLAB_8_6                      ('2015b', 34)
        MATLAB_8_7                      ('2016a', 35)
    end
end 