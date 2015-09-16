TITLE Delayed rectifire
 
COMMENT
  from "An Active Membrane Model of the Cerebellar Purkinje Cell
        1. Simulation of Current Clamp in Slice"
ENDCOMMENT
 

NEURON {
        SUFFIX Kdr
        USEION k WRITE ik
        RANGE  gkbar, gk, minf, hinf, mtau, htau, ik, alpha, beta
}

UNITS {
        (mA) = (milliamp)
        (mV) = (millivolt)
}
 
PARAMETER {
        gkbar	= .6 (mho/cm2)
        ek	= -85 (mV)
}
 
ASSIGNED {
        v (mV)
        ik (mA/cm2)
        mtau
        minf
        htau
        hinf
}

STATE {
        m h
}
 
BREAKPOINT {
        SOLVE states METHOD cnexp
	ik = gkbar*m*m*h* (v-ek)
}
 
UNITSOFF

DERIVATIVE states {  :Computes state variables m,h
        mrates(v)
        m' = (minf-m)/mtau
        h' = (hinf-h)/htau
}
 
INITIAL {
        mrates(v)
        hrates(v)
	m = minf
	h = hinf
}

PROCEDURE mrates(v) {
       LOCAL dummyA, alpha, beta
       dummyA=5
       alpha = -dummyA*0.0047*(v-8)/(exp(-(v-8)/12)-1)
       beta  = dummyA*(exp(-(v+127)/30))
       minf = alpha/(alpha+beta)
         
       alpha = -dummyA*0.0047*(v+12)/(exp(-(v+12)/12)-1)
       beta  = dummyA*(exp(-(v+147)/30))
       mtau  = 1/(alpha+beta)

}

PROCEDURE hrates(v) {
  hinf = 1/(1+exp((v+25)/4))

    if(v<-25) {
        htau = 1200
        }else{
        htau = 10
        }

}

UNITSON

