/run/pinAffinity 1

/control/verbose 1 
/run/verbose 1 
/tracking/verbose 0

/testConfig/WriteHits false
/testConfig/DoAnalysis false
/testConfig/DoStepLimit true
/testConfig/steplengthlimit 0.01 cm
/testConfig/DoProfile true

/run/initialize 
/random/setSeeds 7 38 

/gun/position 0. 0. -4.55 m
/gun/particle G4P_PARTICLE_TYPE
/gun/energy G4P_BEAM_ENERGY GeV
/gun/direction 0. 0. 1.
/run/beamOn G4P_NUMBER_BEAMON
