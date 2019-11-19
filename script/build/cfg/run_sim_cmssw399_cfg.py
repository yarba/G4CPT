# svn keywords:
# $Id: run_sim_cmssw399_cfg.py 455 2010-02-26 23:45:11Z genser $: file info

import FWCore.ParameterSet.Config as cms

process = cms.Process("RSim")

#process.load("Configuration.StandardSequences.SimulationRandomNumberGeneratorSeeds_cff")

process.load("Configuration.StandardSequences.Geometry_cff")
process.load("Configuration.StandardSequences.MagneticField_cff")
process.load("SimG4Core.Configuration.SimG4Core_cff")


process.RandomNumberGeneratorService = cms.Service("RandomNumberGeneratorService",
    g4SimHits = cms.PSet(
        initialSeed = cms.untracked.uint32(11),
        engineName = cms.untracked.string('HepJamesRandom')
    ),
    # to save the status of the last event (useful for crashes)
    saveFileName = cms.untracked.string('seed_save_one.txt')
)



# here we set number of events to process 100:
process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(100)
)
process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring('file:events_zprime_g4.9.3.p02_cms_3_9_9.root')
)

process.configurationMetadata = cms.untracked.PSet(
    version = cms.untracked.string('$Revision: 1.3 $'),
    name = cms.untracked.string('$Source: /cvs_server/repositories/CMSSW/CMSSW/Validation/Geant4Releases/test/G4Val_QGSP_ZprimeDijets_GEN_SIM.cfg,v $'),
    annotation = cms.untracked.string("test G4 version with Z\'->dijets & QGSP")
)

process.load("SimGeneral.HepPDTESSource.pythiapdt_cfi")

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
#process.SimpleProfiling = cms.Service("SimpleProfiling")

#process.out = cms.OutputModule("PoolOutputModule",
#    fileName = cms.untracked.string('output_sim.root')
#)

#
# This thing was a part of the original config but it seems
# to be causing segfault, either in generation or det.simulation...
#
#process.outstr = cms.EDFilter("EventStreamFileWriter",
#    fileName = cms.untracked.string('teststreamfile_copy.dat'),
#    compression_level = cms.untracked.int32(1),
#    use_compression = cms.untracked.bool(True),
#    indexFileName = cms.untracked.string('testindexfile_copy.ind'),
#    max_event_size = cms.untracked.int32(7000000)
#)

process.p1 = cms.Path(process.g4SimHits)
#process.e1 = cms.EndPath(process.out)
process.g4SimHits.Physics.type = 'SimG4Core/Physics/QGSP_BERT'
#process.g4SimHits.MagneticField.delta = 0.0
process.g4SimHits.G4Commands = ['/control/verbose  1']

#process.schedule = cms.Schedule(process.p1,process.e1)
process.schedule = cms.Schedule(process.p1)

