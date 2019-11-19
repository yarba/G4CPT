# svn keywords:
# $Rev: 604 $: Revision of last commit; not used for the file
# $Author: paterno $: Author of last commit
# $Date: 2010-04-11 15:20:47 -0500 (Sun, 11 Apr 2010) $: Date of last commit

# TODO: Move this to CMS-specific directory, preparing for move out of perfdb.

import FWCore.ParameterSet.Config as cms

process = cms.Process("Gen")


process.load("IOMC.EventVertexGenerators.VtxSmearedGauss_cfi")

process.load('Configuration.StandardSequences.Services_cff')
#
# This is the CORRECT format for the RNDM service config.
# Should be fine for any release starting 31X series.
# However, the config of the RNDM service is "local" and thus incomplete 
# - for the full-scale one see IOMC/RandonEngine/python/IOMC_cff.py 
# NOTE: if you load up Services_cff, as shown above, it'll bring in
# IOMC_cff and several other services
#
#process.RandomNumberGeneratorService = cms.Service("RandomNumberGeneratorService",
#    generator = cms.PSet(
#        initialSeed = cms.untracked.uint32(123456789),
#        engineName = cms.untracked.string('HepJamesRandom')
#    ),
#    VtxSmeared = cms.PSet(
#        initialSeed = cms.untracked.uint32(98765432),
#        engineName = cms.untracked.string('HepJamesRandom')
#    ),
#    g4SimHits = cms.PSet(
#        initialSeed = cms.untracked.uint32(11),
#        engineName = cms.untracked.string('HepJamesRandom')
#    )
#    # to save the status of the last event (useful for crashes)
#    ,saveFileName = cms.untracked.string('seed_save_one.txt')
#)

process.source = cms.Source("EmptySource")

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(1000)
)
process.configurationMetadata = cms.untracked.PSet(
    # this may be conflict with the svn repository used by cms & profiling project;
    # we will remove the Rev from svn:keywords property of the file
    version = cms.untracked.string('$Revision: 604 $'),
    name = cms.untracked.string('$Source: /cvs_server/repositories/CMSSW/CMSSW/Validation/Geant4Releases/test/G4Val_QGSP_ZprimeDijets_GEN_SIM.cfg,v $'),
    annotation = cms.untracked.string("test G4 version with Z\'->dijets & QGSP")
)
process.MessageLogger = cms.Service("MessageLogger",

    cout = cms.untracked.PSet(
        default = cms.untracked.PSet(
            limit = cms.untracked.int32(-1)
        ),
        ## threshold = cms.untracked.string('WARNING'),
        threshold = cms.untracked.string('INFO'),
        G4cout = cms.untracked.PSet(
            limit = cms.untracked.int32(-1)
        ),
        G4cerr = cms.untracked.PSet(
            limit = cms.untracked.int32(-1)
        )
    ),
    categories = cms.untracked.vstring('G4cout','G4cerr'),
    destinations = cms.untracked.vstring('cout')
)

from GeneratorInterface.Pythia6Interface.pythiaDefault_cff import *
process.generator = cms.EDFilter("Pythia6GeneratorFilter",
    displayPythiaCards = cms.untracked.bool(True),
    displayPythiaBanner = cms.untracked.bool(True),
    pythiaPylistVerbosity = cms.untracked.int32(0),
    filterEfficiency = cms.untracked.double(1.0),
    pythiaHepMCVerbosity = cms.untracked.bool(False),
    comEnergy = cms.double(14000.0),
    maxEventsToPrint = cms.untracked.int32(0),
    PythiaParameters = cms.PSet(
        pythiaDefaultBlock,
        myParameters = cms.vstring('PMAS(32,1)= 700.            !mass of Zprime', 
            'MSEL=0                      !(D=1) to select between full user control (0, then use MSUB) and some preprogrammed alternative', 
            'MSTP(44) = 3                !only select the Z process', 
            'MSUB(141) = 1               !ff  gamma z0 Z0', 
            'MSTJ(11)=3                 ! Choice of the fragmentation function', 
            'MSTJ(22)=2                 !Decay those unstable particles', 
            'MSTP(2)=1                  !which order running alphaS', 
            'MSTP(33)=0                 !(D=0) inclusion of K factors in (=0: none, i.e. K=1)', 
            'MSTP(51)=7                 !structure function chosen', 
            'MSTP(81)=1                 !multiple parton interactions 1 is Pythia default', 
            'MSTP(82)=4                 !Defines the multi-parton model', 
            'MSTU(21)=1                 !Check on possible errors during program execution', 
            'PARJ(71)=10.               !for which ctau  10 mm', 
            'PARP(82)=1.9               !pt cutoff for multiparton interactions', 
            'PARP(89)=1000.             !sqrts for which PARP82 is set', 
            'PARP(84)=0.4               !Multiple interactions: matter distribution Registered by Chris.Seez@cern.ch', 
            'PARP(90)=0.16              !Multiple interactions: rescaling power Registered by Chris.Seez@cern.ch', 
            'PMAS(5,1)=4.2              !mass of b quark', 
            'PMAS(6,1)=175.             !mass of top quark', 
            'PMAS(23,1)=91.187          !mass of Z', 
            'PMAS(24,1)=80.22           !mass of W', 
            'MDME(289,1)= 1            !d dbar', 
            'MDME(290,1)= 1            !u ubar', 
            'MDME(291,1)= 1            !s sbar', 
            'MDME(292,1)= 1            !c cbar', 
            'MDME(293,1)= 0            !b bar', 
            'MDME(294,1)= 0            !t tbar', 
            'MDME(295,1)= 0            !4th gen Q Qbar', 
            'MDME(296,1)= 0            !4th gen Q Qbar', 
            'MDME(297,1)= 0            !e e', 
            'MDME(298,1)= 0            !neutrino e e', 
            'MDME(299,1)= 0            ! mu mu', 
            'MDME(300,1)= 0            !neutrino mu mu', 
            'MDME(301,1)= 0            !tau tau', 
            'MDME(302,1)= 0            !neutrino tau tau', 
            'MDME(303,1)= 0            !4th generation lepton', 
            'MDME(304,1)= 0            !4th generation neutrino', 
            'MDME(305,1)= 0            !W W', 
            'MDME(306,1)= 0            !H  charged higgs', 
            'MDME(307,1)= 0            !Z', 
            'MDME(308,1)= 0            !Z', 
            'MDME(309,1)= 0            !sm higgs', 
            'MDME(310,1)= 0            !weird neutral higgs HA'),
        parameterSets = cms.vstring('pythiaDefault',
            'myParameters')
    )
)

# these are NOT necessary for Generation !!!
#
process.Timing = cms.Service("Timing")
#process.SimpleProfiling = cms.Service("SimpleProfiling")

process.out = cms.OutputModule("PoolOutputModule",
    fileName = cms.untracked.string('output_generator.root')
)

process.p1 = cms.Path(process.generator*process.VtxSmeared)
process.e1 = cms.EndPath(process.out)

process.schedule = cms.Schedule(process.p1,process.e1)
