#------------------------------------------------------------------------------
# Macro to run cmsExp, a G4 application with a standalone CMS detector geometry
#
# Usage: cmsExp run_cmsExp.g4
#
# Requirement 1) cmsExp.gdml (set CMSEXP_GDML="yourGDML.gdml" to use your own)
#             2) hepevt.data (can be an empty file if generator is particleGun
#
# Option 1) physics list: FTFP_BERT (use env PHYSLIST to select other lists)
#        2) production cut : use /run/setCut 1.0 mm to change the cut
#        3) generator type : /mygen/generator [hepEvent|particleGun]
#        4) particle type : ex) mu- mu+ e- e+ pi- pi+ proton anti_proton 
#
#------------------------------------------------------------------------------
# verbosity
#------------------------------------------------------------------------------
/run/verbose 1 
/event/verbose 0 
/tracking/verbose 0 
#------------------------------------------------------------------------------
# production cut
#------------------------------------------------------------------------------
#/run/setCut 1.0 mm (defaultCutValue = 1.0*mm in G4VUserPhysicsList)
#------------------------------------------------------------------------------
# generator type
#------------------------------------------------------------------------------
/mygen/generator G4P_GENERATOR_TYPE
#------------------------------------------------------------------------------
# set variables if particleGun is selected
#------------------------------------------------------------------------------
/mygen/nParticle  1
/mygen/minEta  -0.50
/mygen/maxEta   0.50
/mygen/minPhi  -3.14
/mygen/maxPhi   3.14
/gun/particle   G4P_PARTICLE_TYPE
/gun/energy     G4P_BEAM_ENERGY GeV
#------------------------------------------------------------------------------
# uniform magnetic field along the +z direction
#------------------------------------------------------------------------------
/mydet/setField G4P_SET_BFIELD tesla
/mydet/fieldType volumebase
#=======================  ADDITIONAL PARAMETERS and INIT  ======
#
#/process/em/auger FLAG
#/process/em/deexcitationIgnoreCut FLAG
#
/run/initialize
#
#------------------------------------------------------------------------------
# number of events
#------------------------------------------------------------------------------
/run/beamOn     G4P_NUMBER_BEAMON 
#------------------------------------------------------------------------------
# end of run_cmsExp.g4
#------------------------------------------------------------------------------
