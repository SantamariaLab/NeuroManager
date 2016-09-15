# Interpreter prefix added automatically by target-side NeuronPythonPrep.m
#   since it is machine-dependent.
# Produces time and voltage data files that are processed externally.

def pythonsim(simid, inputdir, modeldir, outputdir, currentstr, vinitstr, delaystr, stimdurationstr, timestepstr, simstopstr, recordintervalstr):
	import neuron
	from neuron import h
	Section = h.Section

	# All the mods are in the simulator directory
	# Apparently this is already done by  the import, if we use the "-dll" 
	# option in the call to nrniv. Since the import behavior seems to be 
	# inconsistent without the "-dll" option, we do it this way.
	#neuron.load_mechanisms(".")  # SO NOT USING LOAD_MECHANISMS HERE
	# local auto-modified version for no gui and control over certain ion 
	#  channels is in the input dir
	h.xopen(modeldir + '/' + simid + '.hoc') 

	timefilepath = outputdir + '/' + 'timedata.txt'
	timefile = h.File()
	timefile.wopen(timefilepath, 'w')
	
	voltagefilepath = outputdir + '/' + 'voltagedata.txt'
	voltagefile = h.File()
	voltagefile.wopen(voltagefilepath, 'w')

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
	recordlength = simstop/recordinterval + 1
	testt = h.Vector(recordlength)
	testv = h.Vector(recordlength)

    # Recording at the soma
	testt.record(h._ref_t, recordinterval)
	testv.record(h.soma(0.5)._ref_v, recordinterval)

	# Initialize
	h.finitialize(vinit)
	h.fcurrent()

	# Integrate
	while h.t <= simstop:
		v = h.soma.v
		h.fadvance()

	# Shutdown
	testt.printf(timefile, '%f\n')
	testv.printf(voltagefile, '%f\n')
	timefile.close()
	voltagefile.close()
	return(0)
