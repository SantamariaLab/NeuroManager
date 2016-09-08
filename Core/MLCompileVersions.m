% MLCompileVersions
% https://www.mathworks.com/matlabcentral/answers/102061-what-is-the-version-of-the-matlab-compiler-runtime-mcr-that-corresponds-to-the-version-of-matlab-c
classdef MLCompileVersions
    properties
        release;
        compilerVer;
        mcrVer;
    end
    methods
        function t = MLCompileVersions(release, mcrVer, compilerVer)
            t.release = release;
            t.compilerVer = compilerVer;
            t.mcrVer = mcrVer;
        end
    end
    enumeration
        % name       release                mcr       compiler  
        R2011A      ('R2011a (7.12)',       '7.15',   '4.15')
        R2011B      ('R2011b (7.13)',       '7.16',   '4.16')
        R2012A      ('R2012a (7.14)',       '7.17',   '4.17')
        R2012B      ('R2012b (8.0)',        '8.0',    '4.18')
        R2013A      ('R2013a (8.1)',        '8.1',    '4.18.1')
        R2013B      ('R2013b (8.2)',        '8.2',    '5.0')
        R2014A      ('R2014a (8.3)',        '8.3',    '5.1')
        R2014B      ('R2014b (8.4)',        '8.4',    '5.2')
        R2015A      ('R2015a (8.5)',        '8.5',    '5.3')
        R2015ASP1   ('R2015asp1 (8.5.1)',   '8.5.1',  '5.4')
        R2015B      ('R2015b (8.6)',        '8.6',    '5.4')
        R2016A      ('R2016a (9.0)',        '8.7',    '5.5')
        R2016B      ('R2016b (8.8)',        '8.8',    '5.6')
        
           

    end
end 
