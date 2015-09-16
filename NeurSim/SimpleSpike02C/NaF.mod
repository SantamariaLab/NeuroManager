TITLE Fast sodium current
 
COMMENT
ENDCOMMENT
 
NEURON {
        SUFFIX NaF
	USEION na WRITE ina
        RANGE  gnabar, gna, minf, hinf, mexp, hexp
} 

UNITS {
        (mA) = (milliamp)
        (mV) = (millivolt)
}
 
PARAMETER {
        gnabar	= 7.5 (mho/cm2)
        ena	= 45 (mV)
}

ASSIGNED {
        v (mV)
        ina (mA/cm2)
        gna minf hinf mtau htau
}
 
STATE {
        m h
}
 
BREAKPOINT {
        SOLVE states METHOD cnexp
        gna = gnabar *m*m*m*h 
	ina = gna* (v-ena)
}
 
UNITSOFF
 
INITIAL {
	mrates(v)
        hrates(v)
	m = minf
	h = hinf
}

DERIVATIVE states {
        mrates(v)
        hrates(v)
        m' = (minf-m)/mtau
        h' = (hinf-h)/htau
}

PROCEDURE mrates(v) {
        LOCAL alpha, beta
        alpha = 35/exp((v+5)/(-10))
        beta =  7/exp((v+65)/20)
        minf = alpha/(alpha+beta)
        mtau = 1/(alpha+beta)
}

PROCEDURE hrates(v) {
        LOCAL alpha, beta
        alpha = 0.225/(1+exp((v+80)/10))
        beta = 7.5/exp((v-3)/(-18))
        hinf = alpha/(alpha+beta)
        htau = 1/(alpha+beta)
}
 
UNITSON

