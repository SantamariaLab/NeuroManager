classdef MATLABMachineInfo < handle
    properties
        compilerDir;
        compiler;
        executable;
        mcrDir;
        xCompDir;
    end
    
    methods 
        function obj = MATLABMachineInfo(compilerDir, compiler, ...
                                         executable, mcrDir, xCompDir)
            obj.compilerDir = compilerDir;
            obj.compiler = compiler;
            obj.executable = executable;
            obj.mcrDir = mcrDir;
            obj.xCompDir = xCompDir;
        end
        
        % ---
        function dir = getCompilerDir(obj)
            dir = obj.compilerDir;
        end
        
        % ---
        function dir = getCompiler(obj)
            dir = obj.compiler;
        end
        
        % ---
        function dir = getExecutable(obj)
            dir = obj.executable;
        end
        
        % ---
        function dir = getMcrDir(obj)
            dir = obj.mcrDir;
        end
        
        % ---
        function dir = getXCompDir(obj)
            dir = obj.xCompDir;
        end
      
    end
end
