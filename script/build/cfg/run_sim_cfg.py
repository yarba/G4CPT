# svn keywords:
# $Rev: 347 $: Revision of last commit; not used for the file
# $Author: paterno $: Author of last commit
# $Date: 2010-04-11 15:20:47 -0500 (Sun, 11 Apr 2010) $: Date of last commit

# TODO: Move this to CMS-specific directory, preparing for move out of perfdb.

import FWCore.ParameterSet.Config as cms

process = cms.Process("RSim")

process.load("Configuration.StandardSequences.SimulationRandomNumberGeneratorSeeds_cff")

process.load("Configuration.StandardSequences.Geometry_cff")
process.load("Configuration.StandardSequences.MagneticField_cff")
process.load("SimG4Core.Configuration.SimG4Core_cff")

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(100)
)
process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring('file:our_pretty_events.root')
)

process.configurationMetadata = cms.untracked.PSet(
    # this may be conflict with the svn repository used by cms & profiling project;
    # we will remove the Rev from svn:keywords property of the file 
    version = cms.untracked.string('$Revision: 1.3 $'),
    name = cms.untracked.string('$Source: /cvs_server/repositories/CMSSW/CMSSW/Validation/Geant4Releases/test/G4Val_QGSP_ZprimeDijets_GEN_SIM.cfg,v $'),
    annotation = cms.untracked.string("test G4 version with Z\'->dijets & QGSP")
)

#process.MessageLogger = cms.Service("MessageLogger",
#    cout = cms.untracked.PSet(
#        default = cms.untracked.PSet(
#            limit = cms.untracked.int32(0)
#        ),
#        INFO = cms.untracked.PSet(
#            limit = cms.untracked.int32(-1)
#        )
#    ),
#    destinations = cms.untracked.vstring('cout')
#)

process.MessageLogger = cms.Service("MessageLogger",
    ## debugModules = cms.untracked.vstring('*'),
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

process.Timing = cms.Service("Timing")
process.SimpleProfiling = cms.Service("SimpleProfiling")

process.RandomNumberGeneratorService = cms.Service("RandomNumberGeneratorService",
    moduleSeeds = cms.PSet(
        g4SimHits = cms.untracked.uint32(9876),
        VtxSmeared = cms.untracked.uint32(98765432)
    ),
    sourceSeed = cms.untracked.uint32(123456789),
    saveFileName = cms.untracked.string('seed_save_one.txt')
)

process.out = cms.OutputModule("PoolOutputModule",
    fileName = cms.untracked.string('output_sim.root')
)

process.p1 = cms.Path(process.g4SimHits)
process.e1 = cms.EndPath(process.out)
process.g4SimHits.Physics.type = 'SimG4Core/Physics/QGSP_BERT'
#process.g4SimHits.MagneticField.delta = 0.0
process.g4SimHits.G4Commands = ['/control/verbose  1']

