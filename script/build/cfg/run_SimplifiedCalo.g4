#----------------------------------------------------------------
#
# This is the prototype of the Geant4 command script for the
# statistical acceptance suite, based on a Calorimeter setup.
# The user has to make the following choices (in practice, 
# commenting/uncommeting few lines below):
#  1) Production range cut :
#     by default the range cut is set to 0.7 mm ; 
#     to set it explicitly, e.g. to 1 cm, you need the following
#     macro command:
#       /run/setCut 1.0 cm
#  2) Choice of the  * Particle Type * :
#       mu-, mu+, e-, e+, gamma, 
#       pi-, pi+, kaon-, kaon+, kaon0L, 
#       neutron, proton,
#       anti_neutron, anti_proton,
#       deuteron, triton, alpha. 
#  3) Choice of the  * Beam Energy * :
#       1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50, 60, 80,
#       100, 120, 150, 180, 200, 250, 300, 1000    GeV.
#  4) Choice is of the uniform magnetic field along the Y-direction.
#     By default, it is 0.0 . 
#     Explicit unit (e.g. tesla) should be used to express the B value.
#  5) Choice of the  * Calorimeter Type * :
#       I) Absorber and Active materials (and whether it is
#          an homogeneous calorimeter or a sampling one):
#            Fe-Sci, Cu-Sci, Pb-Sci, Cu-LAr, Pb-LAr, W-LAr  (Sampling) 
#            PbWO4, Graphite (Homogeneous)
#      II) Dimension and Segmentation:
#          - Is the unit with which to express the dimension of
#            the absorber in lambdas (interaction lengths), or
#            in [mm]?
#          - Size of the absorber in the given unit.
#          - Radius of the (cylindrical) calorimeter in the given unit.
#          - Number of active layers (in the case of PbWO4, i.e.
#            of a homogeneous calorimeter, this number is relevant
#            for the longitudinal shower analysis).
#          - Size of the active layer, in [mm].
#          - Number of readout layers (which must be a divisor
#            of the number of active layers). 
#          Then, for the transverse shower analysis:
#          - Is the unit with which to express the radius bin
#            size in lambdas (interaction lengths) of the absorber,
#            or in [mm]?	
#          - Size of the first bin for the radius (transverse 
#            distance from the beam axis): the other ones will
#            have increasing widths (e.g. the second bin has
#            a width equal to two times the first bin size,
#            the third one has a width equal to three times
#            the first bin size, etc.).
#          - Number of bins for the radius.
#     III) Update Geometry : always necessary, leave it On!
#
#----------------------------------------------------------------
#/random/resetEngineFrom start.rndm
#/random/setSavingFlag 1
#
/run/verbose 1 
/event/verbose 0 
/tracking/verbose 0 
#
#=======================  PRODUCTION RANGE CUT ==============
#
#/run/setCut 1.0 cm
#
#=======================  GENERATOR TYPE  ====================
#
/mygen/generator G4P_GENERATOR_TYPE
# 
#=======================  PARTICLE TYPE  ====================
#
/gun/particle G4P_PARTICLE_TYPE
#/gun/particle mu-
#/gun/particle mu+
#/gun/particle e-
#/gun/particle e+
#/gun/particle gamma
#/gun/particle pi-
#/gun/particle pi+
#/gun/particle kaon-
#/gun/particle kaon+
#/gun/particle kaon0L
#/gun/particle neutron
#/gun/particle proton
#/gun/particle anti_neutron
#/gun/particle anti_proton
#/gun/particle deuteron 
#/gun/particle triton 
#/gun/particle alpha 
#/gun/particle lambda
#
#=======================  BEAM ENERGY  ====================
#
/gun/energy   G4P_BEAM_ENERGY GeV
#/gun/energy    1 GeV
#/gun/energy    2 GeV
#/gun/energy    3 GeV
#/gun/energy    4 GeV
#/gun/energy    5 GeV
#/gun/energy    6 GeV
#/gun/energy    7 GeV
#/gun/energy    8 GeV
#/gun/energy    9 GeV
#/gun/energy   10 GeV
#/gun/energy   20 GeV
#/gun/energy   30 GeV
#/gun/energy   40 GeV
#/gun/energy   50 GeV
#/gun/energy   60 GeV
#/gun/energy   80 GeV
#/gun/energy  100 GeV
#/gun/energy  120 GeV
#/gun/energy  150 GeV
#/gun/energy  180 GeV
#/gun/energy  200 GeV
#/gun/energy  250 GeV
#/gun/energy  300 GeV
#/gun/energy 1000 GeV
#
#=======================  MAGNETIC FIELD  ====================
#
/mydet/setField G4P_SET_BFIELD tesla
#
#=======================  CALORIMETER TYPE  ====================
#
#=== I) ABSORBER and ACTIVE MATERIALS; and SAMPLING/HOMOGENEOUS TYPE ===
#
#--- Iron - Scintillator
#/mydet/absorberMaterial Iron
#/mydet/activeMaterial Scintillator
#/mydet/isCalHomogeneous 0
#
#--- Copper - Scintillator
/mydet/absorberMaterial Copper
/mydet/activeMaterial Scintillator
/mydet/isCalHomogeneous 0
#
#--- Lead - Scintillator
#/mydet/absorberMaterial Lead
#/mydet/activeMaterial Scintillator
#/mydet/isCalHomogeneous 0
#
#--- Copper - LiquidArgon
#/mydet/absorberMaterial Copper
#/mydet/activeMaterial LiquidArgon
#/mydet/isCalHomogeneous 0
#
#--- Lead - LiquidArgon
#/mydet/absorberMaterial Lead
#/mydet/activeMaterial LiquidArgon
#/mydet/isCalHomogeneous 0
#
#--- Tungsten - LiquidArgon
#/mydet/absorberMaterial Tungsten
#/mydet/activeMaterial LiquidArgon
#/mydet/isCalHomogeneous 0
#
#--- PbWO4 ---
#/mydet/absorberMaterial PbWO4
#/mydet/activeMaterial PbWO4
#/mydet/isCalHomogeneous 1
#
#--- Walloy/scintillator CALICE AHCAL
#/mydet/absorberMaterial AHCALWalloy
#/mydet/activeMaterial Scintillator
#/mydet/isCalHomogeneous 0



# Exotic combinations of materials

#--- Block of Graphite ---
#/mydet/absorberMaterial Graphite
#/mydet/activeMaterial Graphite
#/mydet/isCalHomogeneous 1
#
#-- Fake Materials for ATLAS bug
#For this kind of material dimensions cannot be
#specified in units of lambda
#/mydet/absorberMaterial ultraDenseHelium
#/mydet/activeMaterial ultraDenseHelium
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial ultraDenseHelium
#/mydet/activeMaterial ultraDenseHelium
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Copper
#/mydet/activeMaterial Copper
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Germanium
#/mydet/activeMaterial Germanium
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Aluminium
#/mydet/activeMaterial Aluminium
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Silicon 
#/mydet/activeMaterial Silicon
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Brass 
#/mydet/activeMaterial Brass
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Graphite 
#/mydet/activeMaterial  Graphite
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Lead 
#/mydet/activeMaterial Lead
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Tungsten 
#/mydet/activeMaterial Tungsten
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial LAr 
#/mydet/activeMaterial LAr
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Uranium
#/mydet/activeMaterial Uranium
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial PbWO4 
#/mydet/activeMaterial PbWO4
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial ultraDenseHidrogen
#/mydet/activeMaterial ultraDenseHidorgen
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Lithium 
#/mydet/activeMaterial Lithium
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Beryllium 
#/mydet/activeMaterial Beryllium
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Deuterium
#/mydet/activeMaterial Deuterium
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Boron
#/mydet/activeMaterial Boron
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Nitrogen
#/mydet/activeMaterial Nitrogen
#/mydet/isCalHomogeneous 0

#/mydet/absorberMaterial Oxygen
#/mydet/activeMaterial Oxygen
#/mydet/isCalHomogeneous 0

#=== II) DIMENSION and SEGMENTATION ===
#
/mydet/isUnitInLambda 0
/mydet/absorberTotalLength 7000
/mydet/calorimeterRadius 3000

#/mydet/isUnitInLambda 1
#/mydet/absorberTotalLength 10.0
#/mydet/calorimeterRadius 5.0
/mydet/activeLayerNumber 100
/mydet/readoutLayerNumber 20
/mydet/activeLayerSize 4.0
#/mydet/isRadiusUnitInLambda 1
/mydet/radiusBinSize 0.1
/mydet/radiusBinNumber 10
#
#=== III) UPDATE GEOMETRY : leave it always ON ! ===
#
/mydet/update


#MESH Scoring...
#Iron Calorimeter: Length: 10 lambda * 16.76 cm ; Cyl. radious 5*16.76 
#/score/create/boxMesh boxMesh_1
#/score/mesh/boxSize 83.80 83.80 100 cm
#/score/mesh/nBin 30 30 30
#/score/quantity/energyDeposit eDep 
#/score/close
#/score/list
#
#=======================  ADDITIONAL PARAMETERS and INIT  ======
#
#/process/em/auger FLAG
#/process/em/deexcitationIgnoreCut FLAG
#
#/process/em/applyCuts false
#
/run/initialize
#
#=======================  NUMBER OF EVENTS  ====================
#
/run/beamOn   G4P_NUMBER_BEAMON
#/run/beamOn     1
#/run/beamOn     2
#/run/beamOn    10 
#/run/beamOn    25 
#/run/beamOn    50 
#/run/beamOn   100
#/run/beamOn   500
#/run/beamOn  1000
#/run/beamOn  5000
#/run/beamOn 10000
#
#/score/drawProjection boxMesh_1 eDep
#/score/dumpAllQuantitiesToFile boxMesh_1 all.txt 

#/particle/select pi+
#/particle/process/dump
#/process/inactivate msc
#/process/inactivate Decay
#/process/inactivate hIoni
#/process/inactivate hBrems
#/process/inactivate hPairProd
#/process/inactivate hElastic
#/particle/select pi+
#/particle/process/dump
#/run/beamOn 10000000
