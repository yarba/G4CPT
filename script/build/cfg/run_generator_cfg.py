# svn keywords:
# $Rev: 346 $: Revision of last commit; not used for the file
# $Author: paterno $: Author of last commit
# $Date: 2010-04-11 15:20:47 -0500 (Sun, 11 Apr 2010) $: Date of last commit

# TODO: Move this to CMS-specific directory, preparing for move out of perfdb.

import FWCore.ParameterSet.Config as cms

process = cms.Process("Generate")

process.load("Configuration.StandardSequences.SimulationRandomNumberGeneratorSeeds_cff")

#process.load("Configuration.JetMET.calorimetry_gen_Zprime_Dijets_700_cff")

process.load("Configuration.Generator.ZMM_cfi")

process.load("IOMC.EventVertexGenerators.VtxSmearedGauss_cfi")

###process.load("SimG4Core.Configuration.SimG4Core_cff")

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(1000)
)
process.configurationMetadata = cms.untracked.PSet(
    # this may be conflict with the svn repository used by cms & profiling project;
    # we will remove the Rev from svn:keywords property of the file 
    version = cms.untracked.string('$Revision: 1.3 $'),
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
    fileName = cms.untracked.string('output_generator.root')
)

process.outstr = cms.EDFilter("EventStreamFileWriter",
    fileName = cms.untracked.string('teststreamfile_copy.dat'),
    compression_level = cms.untracked.int32(1),
    use_compression = cms.untracked.bool(True),
    indexFileName = cms.untracked.string('testindexfile_copy.ind'),
    max_event_size = cms.untracked.int32(7000000)
)

#process.p1 = cms.Path(process.VtxSmeared)
process.p1 = cms.Path(process.generator*process.VtxSmeared)
process.e1 = cms.EndPath(process.out*process.outstr)
###process.g4SimHits.Physics.type = 'SimG4Core/Physics/QGSP_BERT'


