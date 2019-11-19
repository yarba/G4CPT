# svn keywords:
# $Id: run_sim_cmssw_cfg.py 2010-02-26 23:45:11 genser $: file info

import FWCore.ParameterSet.Config as cms

process = cms.Process("RSim")

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

# number of events to process
process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(100)
)
process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring('file:events_zprime.root')
)

process.load("SimGeneral.HepPDTESSource.pythiapdt_cfi")

process.g4SimHits.Physics.type = 'SimG4Core/Physics/QGSP_BERT'
process.g4SimHits.G4Commands = ['/control/verbose  1']

process.MessageLogger = cms.Service("MessageLogger",
    cout = cms.untracked.PSet(
        default = cms.untracked.PSet(
            limit = cms.untracked.int32(-1)
        ),
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

#check timing
process.Timing = cms.Service("Timing")

#Add the configuration for the Igprof running to dump profile snapshots:
process.IgProfService = cms.Service("IgProfService",
   reportFirstEvent        = cms.untracked.int32(0),
   reportEventInterval     = cms.untracked.int32(25),
   reportToFileAtPostEvent = cms.untracked.string("| gzip -c > IgProf.QCD.%I.gz")
)

process.p1 = cms.Path(process.g4SimHits)
process.schedule = cms.Schedule(process.p1)

