# Comes from STGFeatExtrFromDB; remove all database access for use on remotes.
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
import pprint

from pprint import pprint

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
# runDir              = sys.argv[11]
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
# timeFile = outDir + '/' + timeFilename
# voltageFile = outDir + '/' + voltageFilename
# stimulusFile = outDir + '/' + stimulusFilename
featuresFile = outDir + '/' + featuresFilename
timeFile = outDir + '/' + timeFileName
voltageFile = outDir + '/' + voltageFileName
stimulusFile = outDir + '/' + stimulusFileName 
f.write("Files: " + timeFile + " " + voltageFile + " " + 
                    stimulusFile + " " + featuresFile + "\n")

time =     np.loadtxt(timeFile)
time /= 1e3 # convert from mseconds to seconds
voltage =  np.loadtxt(voltageFile)
stimulus = np.loadtxt(stimulusFile)

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
# START USE ABISweepFX here
fx = EphysFeatureExtractor()      # +++++++++++++++++++++++++++++++++++++++++++
try:
    fx.process_instance("", voltage, stimulus, time, 
                        analysis_start/1000, analysis_duration/1000, "")
except:
    print "Problem processing instance..."
    if useTraceback:
        traceback.print_exc()

feature_data = fx.feature_list[0].mean  # See ABI code
# print "feature_data", feature_data
# Pull out the specific features for entry into the database
numSpikes = feature_data['n_spikes']
hasSpikes = (numSpikes != 0)
if not hasSpikes:
    print "no spikes found"
    latency = None
    ISIMean = None
#     ISIFirst = None
    ISICV = None
    adaptation = None
    threshold = None
else:
    if numSpikes == 1:
        print "one spike found"
        latency = feature_data['latency']
        ISIMean = None
#         ISIFirst = None
        ISICV = None
        adaptation = None
        threshold = feature_data['threshold']
    else: # numSpikes > 1
        print "Number of spikes found: ", numSpikes
        latency = feature_data['latency']
        ISIMean = feature_data['isi_avg']
#         ISIFirst = feature_data['first_isi']
        ISICV = feature_data['ISICV']  # seconds or mseconds?
        adaptation = feature_data['adapt']
        threshold = feature_data['threshold']
        print "\n[14]: Individual spike data from EphysFeatureExtractor"
        for i in range(0,numSpikes):
            print "Spike data for spike ", i 
            pprint(feature_data["spikes"][i])
        
        
if 'f_peak' in feature_data: 
    averageSpikePeak = feature_data['f_peak']
else:
    averageSpikePeak = None  

print "Sweep processing now"     
sfx = EphysSweepFeatureExtractor(time, voltage, stimulus, 
                                 analysis_start/1000, 
                                 analysis_duration/1000)  # +++++++++++++++++++
if numSpikes >= 2:  # process_spikes() does not work if fewer than 2
    try:
        print "Processing spikes now"
        sfx.process_spikes()
        print "Spikes processed"
        
        try:
            avgFiringRate = sfx.sweep_feature('avg_rate')
        except:
            avgFiringRate = None

        print "avgFiringRate", avgFiringRate
                
        try:
            # isi stuff from feature extractor is in msecs, whereas 
            # isi stuff from sweep feature extractor is in seconds, so we 
            # ensure both are in msec.
            ISIFirst = sfx.sweep_feature('first_isi')*1000
        except:
            ISIFirst = None
 
        print "ISIFirst:", ISIFirst 

        try:
            # isi stuff from feature extractor is in msecs, whereas 
            # isi stuff from sweep feature extractor is in seconds, so we 
            # ensure both are in msec.
            ISIMeanSweep = sfx.sweep_feature('mean_isi')*1000
        except:
            ISIMeanSweep = None
 
        print "ISIMeanSweep:", ISIMeanSweep

        try:
            print ("Burst data for this experiment (max_burstiness_index " + 
                   "- normalized max rate in burst vs out, num_bursts - " + 
                   "number of bursts detected):")
            burstMetrics = sfx.burst_metrics()
#             pprint(burstMetrics)
            maxBurstiness = burstMetrics[0]
            numBursts = burstMetrics[1]
            hasBursts = numBursts!=0
        except:
            maxBurstiness = None
            numBursts = 0
            hasBursts = False
            if useTraceback:
                traceback.print_exc()
            print "No burst in this experiment"
            
        try:
            print ("Pause data for this experiment (num_pauses - " + 
                   "number of pauses detected, pause_fraction - fraction " + 
                   "of interval [between start and end] spent in a pause):")
            pauseMetrics = sfx.pause_metrics()
#             pprint(pauseMetrics)
            numPauses = pauseMetrics[0]
            hasPauses = numPauses!=0
            pauseFraction = pauseMetrics[1]
        except:
            numPauses = 0
            hasPauses = False
            pauseFraction = None
            if useTraceback:
                traceback.print_exc()
            print "No pause in this experiment"
            
        try: 
            print ("Delay data for this experiment (delay_ratio - ratio of " + 
                   "latency to tau [higher means more delay], tau - dominant " + 
                   "time constant of rise before spike):")
            delayMetrics = sfx.delay_metrics()
            print "Delay metrics: type ", type(delayMetrics[0]), type(delayMetrics[1])
            pprint(delayMetrics)
            delayRatio = delayMetrics[0]
            # Test necessary because ABI SDK not consistent
            if delayRatio.dtype == 'numpy.float64' and np.isnan(delayRatio):
                delayRatio = None
                
            delayTau = delayMetrics[1]
            # Test necessary because ABI SDK not consistent
            if delayTau.dtype == 'numpy.float64' and np.isnan(delayTau):
                delayTau = None
            
        except:
            delayRatio = None
            delayTau = None
            if useTraceback:
                traceback.print_exc()
            print "No delay in this experiment"
    except:
        if useTraceback:
            traceback.print_exc()
        print "process_spikes() failed"
else:  # (if numSpikes >= 2)
    avgFiringRate = None
    ISIFirst = None
    hasBursts = False
    numBursts = 0
    maxBurstiness = None
    hasPauses = False
    numPauses = 0
    pauseFraction = None
#     hasDelays = False
    delayRatio = None
    delayTau = None

# Fill a dictionary with the results and then save to file
features = dict()
features['simID']               = simID
features['analysisStart']       = analysis_start                              #                                  
features['analysisDuration']    = analysis_duration                           # 
features['adaptation']          = adaptation                                  # 
features['avgFiringRate']       = avgFiringRate                               # spikes per second
features['hasSpikes']           = hasSpikes                                   # 1=true;0=false
features['numSpikes']           = numSpikes                                   # 
features['hasBursts']           = hasBursts                                   # 1=true;0=false
features['numBursts']           = numBursts                                   #
features['maxBurstiness']       = maxBurstiness                               #
features['hasPauses']           = hasPauses                                   # 1=true;0=false
features['numPauses']           = numPauses                                   #
features['pauseFraction']       = pauseFraction                               #
# features['hasDelays']           = hasDelays
features['delayRatio']          = delayRatio                                  #
features['delayTau']            = delayTau                                    #
features['first_isi']           = ISIFirst                                    # in milliseconds
features['mean_isi']            = ISIMean                                     # in milliseconds
features['isi_cv']              = ISICV                                       # dimensionless
features['f_peak']              = averageSpikePeak                            # millivolts
# This latency is from the beginning of the "sweep", not the analysis window,
# because we have modified feature_extractor.py to analyze the entire window.
# This is not latency from the start of the stimulus, and is the same as the 
# time of the first spike threshold.
features['latency']             = latency
# stimulusLatency is from stimulus start to the first spike threshold
if latency is not None:
    features['stimulusLatency']     = latency - stimStart
else:
    features['stimulusLatency']     = None
    
features['threshold']           = threshold

features['spikeData'] = []
for i in range(0,numSpikes):
    feature_data["spikes"][i]['spikeNumber'] = i
    features['spikeData'].append(feature_data["spikes"][i])

# END USE ABISweepFX here
 

json.dump(features, open(featuresFile,'w'), indent=4)
#json.dump(features, open(featuresFile,'w'))

f.close()
