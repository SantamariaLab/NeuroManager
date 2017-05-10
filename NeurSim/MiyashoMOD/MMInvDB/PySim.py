# MMInvDB-modified version to eliminate recording interval and to add stimulus recording
# Interpreter prefix added automatically by target-side NeuronPythonPrep.m
#   since it is machine-dependent.
# Produces time, current, and voltage data files that are processed externally.
# recordintervalstr DISABLED
def pythonsim(simid, rundir, inputdir, modeldir, outputdir, currentstr, vinitstr, delaystr, stimdurationstr, timestepstr, simstopstr, recordintervalstr):
	import neuron
	from neuron import h
	Section = h.Section

	# All the mods are in the simulator directory
	# Apparently this is already done by  the import, if we use the "-dll" 
	# option in the call to nrniv. Since the import behavior seems to be 
	# inconsistent without the "-dll" option, we do it this way.
	#neuron.load_mechanisms(".")  # SO NOT USING LOAD_MECHANISMS HERE
	# local auto-modified version for no gui and control over certain ion 
	#  channels is in the run dir
	h.xopen(rundir + '/' + simid + '.hoc') 

	timefilepath = outputdir + '/' + 'timedata.txt'
	timefile = h.File()
	timefile.wopen(timefilepath, 'w')
	
	voltagefilepath = outputdir + '/' + 'voltagedata.txt'
	voltagefile = h.File()
	voltagefile.wopen(voltagefilepath, 'w')

	stimulusfilepath = outputdir + '/' + 'stimulusdata.txt'
	stimulusfile = h.File()
	stimulusfile.wopen(stimulusfilepath, 'w')

	current = float(currentstr)
	vinit = float(vinitstr)
	delay = float(delaystr)
	stimduration = float(stimdurationstr)
	timestep = float(timestepstr)
	simstop = float(simstopstr)
	recordinterval = float(recordintervalstr)
	
	# ----- Current Injection
	stim = h.IClamp(0.5, sec=h.soma)
	stim.amp = current  # nA
	stim.delay = delay  # msec
	stim.dur = stimduration # msec

	# ----- Simulation Control (now mostly done through input arguments)
	h.dt = timestep

	# Preallocate record vectors for speed
	# Requires recordinterval to be an exact multiple of tstep.
#	recordlength = simstop/recordinterval + 1
	recordlength = simstop/timestep + 1
	testt = h.Vector(recordlength)
	testv = h.Vector(recordlength)
	tests = h.Vector(recordlength)

    # Recording at the soma
	#testt.record(h._ref_t, recordinterval)
	#testv.record(h.soma(0.5)._ref_v, recordinterval)
	testt.record(h._ref_t)
	testv.record(h.soma(0.5)._ref_v)

	# Initialize
	h.finitialize(vinit)
	h.fcurrent()

	# Integrate
	while h.t <= simstop:
		v = h.soma.v
		tests.append(stim.i)
		h.fadvance()

	# Shutdown
	testt.printf(timefile, '%f\n')
	testv.printf(voltagefile, '%f\n')
	tests.printf(stimulusfile, '%f\n')
	timefile.close()
	voltagefile.close()
	stimulusfile.close()
	return(0)
