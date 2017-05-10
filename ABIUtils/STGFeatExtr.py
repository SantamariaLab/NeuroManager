# ABI Feature extraction for remote no-console function on remotes.
# print statements go into FXout.txt in the downloaded files for each
# simulation, and the f.write statements go into pytemp.txt.
print "Importing..."
import sys
import numpy as np
# import matplotlib.pyplot as plt
# For remote use, the remainder of the library is not around
# from allensdk.ephys.feature_extractor import EphysFeatureExtractor
# from allensdk.ephys.ephys_extractor import EphysSweepFeatureExtractor
from feature_extractor import EphysFeatureExtractor
from ephys_extractor import EphysSweepFeatureExtractor
import traceback
import json
import math

useTraceback = False     # True/False
print 'Number of arguments:', len(sys.argv), 'arguments.'
print 'Argument List:', str(sys.argv)

simID               = sys.argv[1]
timeFileName        = sys.argv[2]
voltageFileName     = sys.argv[3]
stimulusFileName    = sys.argv[4]
simDurationStr      = sys.argv[5]
stimStartStr        = sys.argv[6]
stimDurationStr     = sys.argv[7]
analysisStartStr    = sys.argv[8]
analysisDurationStr = sys.argv[9]
featuresFilename    = sys.argv[10]
outDir              = sys.argv[11]

f = open(outDir + "/pytemp.txt", 'w')
f.write("simID: " +               simID +               "\n") 
f.write("timeFileName: " +        timeFileName +        "\n")          
f.write("voltageFileName: " +     voltageFileName +     "\n")       
f.write("stimulusFileName: "+     stimulusFileName +    "\n")      
f.write("simDurationStr: "+       simDurationStr +      "\n")    
f.write("stimStartStr: "+         stimStartStr +        "\n")      
f.write("stimDurationStr: "+      stimDurationStr +     "\n")   
f.write("analysisStartStr: "+     analysisStartStr +    "\n")  
f.write("analysisDurationStr: "+  analysisDurationStr + "\n") 
f.write("featuresFilename: "+     featuresFilename +    "\n")  
f.write("outDir: "+               outDir +              "\n")            

simDuration = float(simDurationStr)
stimStart = float(stimStartStr)
stimDuration = float(stimDurationStr)
analysisStart = float(analysisStartStr)
analysisDuration = float(analysisDurationStr)

# Retrieve data for extraction
f.write("Loading data files now..." + "\n")
featuresFile = outDir + '/' + featuresFilename
timeFile = outDir + '/' + timeFileName
voltageFile = outDir + '/' + voltageFileName
stimulusFile = outDir + '/' + stimulusFileName 
f.write("Files: " + timeFile + " " + voltageFile + " " + 
                    stimulusFile + " " + featuresFile + "\n")

time = np.loadtxt(timeFile) # raw data already in seconds
voltage =  np.loadtxt(voltageFile)
voltage *= 1e3 # convert from volts to mV
stimulus = np.loadtxt(stimulusFile)
stimulus *= 1e12 # convert from amps to pA

# Retrieve time parameters for extraction
# Get these somewhere...
# Temporary patch-ins
# Get from shtmgoaldb.simulationRuns (simulationDuration)
simulationDuration = simDuration # (msec)

# get from shtmgoaldb.ipvs  (stimulusStartTime and pulseWidth)
stimulusStart = stimStart      # msec  (convert to seconds below for fx) 
stimulusDuration = stimDuration  # (pulseWidth; msec) (convert to seconds below for fx)

# Calculate these here
# start of simulation for now (abi begins at beginning of stimulus?)
analysis_start = analysisStart       # msec  (convert to seconds below for fx)
# entire simulation for now
# msec (convert to seconds below for fx) hopefully don't need to go to indices
analysis_duration = analysisDuration 

# Perform the feature extractions
f.write("Doing FX now..." + "\n")


from ABISweepFX import ExtractSweepFeatures
analysisStart = analysisStart/1000       # convert from msec to sec
analysisDuration = analysisDuration/1000 # convert from msec to sec
stimulusStart = stimulusStart/1000       # convert from msec to sec
verbose = True
features = ExtractSweepFeatures(time, voltage, stimulus, analysisStart, 
                                analysisDuration, stimulusStart, verbose)
if 'spikeData' in features:
    for spike in features['spikeData']:
        for (k,v) in spike.items():
            print k, ",", v
            if not isinstance(v, basestring):
                if isinstance(v, float):
                    if math.isnan(v):
                        spike[k] = "_NaN_"
                        print "Converted ", k

json.dump(features, open(featuresFile,'w'), indent=4)

f.close()
