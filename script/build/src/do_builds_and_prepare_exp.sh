#!/bin/bash

# svn keywords:
# $Rev: 747 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-08-12 13:06:58 -0500 (Fri, 12 Aug 2011) $: Date of last commit

# TODO: Move this to CMS-specific directory, preparing for move out of perfdb.

GEANT_RELEASE=$1
CMS_RELEASE=$2
if [ ${3:+1} ]
then
    CMS_CVS_RELEASE=$3
else
    CMS_CVS_RELEASE=$CMS_RELEASE
fi
CONFIG_FILE=${4:-run_sim_cmssw399_cfg.py}
LOCAL_WORK_AREA=${5:-/storage/local/data1/geant4work}
BLUEARC_WORK_AREA=${6:-/uscms_data/d2/genser/geant4run}
BLUEARC_OUTPUT_AREA=${7:-/uscms_data/d2/genser/geant_output}

echo "${0} called   with $1 $2 $3 $4 $5 $6 $7"
echo "${0} starting with ${GEANT_RELEASE} ${CMS_RELEASE} ${CMS_CVS_RELEASE} ${CONFIG_FILE} ${LOCAL_WORK_AREA} ${BLUEARC_WORK_AREA} ${BLUEARC_OUTPUT_AREA}"

#this script has to exit if the cms environment is aready set...

if [ "undefined" != ${CMS_PATH:-undefined} ] 
then
    echo "Warning: CMS environment is already set: CMS_PATH ${CMS_PATH}"
    echo "This script has to be run from a new session without CMS environment set"
    exit 1
fi

#CMS_RELEASE=3_5_0_pre5
#GEANT_RELEASE=9.2.p01

# here will we also check for the existence of the next dir... (and make it a parameter...)

#note no "" in the assignment below
WORK_DIR=~/svn/perfdb

if [ -z "${WORK_DIR}" ] || [ ! -d "${WORK_DIR}" ]
then
    echo "${0} problem with WORK_DIR $WORK_DIR"
fi

cd ${WORK_DIR}

echo "running make_new_geant_release.sh"
# we do not do | tee as it changes the meaning of $?
time src/make_new_geant_release.sh ${GEANT_RELEASE} ${CMS_RELEASE} &> \
logs/make_new_geant_release.log_`date +%Y%m%d_%H%M%S`

rc=$?
echo "${0} rc: $rc"

if [ $rc -ne 0 ]
then 
    echo "${0} exiting due to error $rc"
    exit $rc
fi

# "populate" cmssw project areas (~3min):
# this step may also need a "modified" only version

echo "running make_new_cmssw_release.sh"
time src/make_new_cmssw_release.sh ${GEANT_RELEASE} ${CMS_RELEASE} ${CMS_CVS_RELEASE} &> \
logs/make_new_cmssw_release.log_`date +%Y%m%d_%H%M%S`

rc=$?
echo "${0} rc: $rc"

if [ $rc -ne 0 ]
then 
    echo "${0} exiting due to error $rc"
    exit $rc
fi

# note that there is a node disk configuration dependence in the first argument below...

echo "running fix_tool_description"
time ruby src/fix_tool_description ${LOCAL_WORK_AREA} ${GEANT_RELEASE} ${CMS_RELEASE} &> \
logs/fix_tool_description.log_`date +%Y%m%d_%H%M%S`

rc=$?
echo "${0} rc: $rc"

if [ $rc -ne 0 ]
then 
    echo "${0} exiting due to error $rc"
    exit $rc
fi

# now do the scram build:
# note that there is a node disk configuration dependence in the first argument below...

echo "running do_scram_build.rb"
time src/do_scram_build.rb ${LOCAL_WORK_AREA}  ${GEANT_RELEASE} ${CMS_RELEASE} &> \
logs/do_scram_build.log_`date +%Y%m%d_%H%M%S`

rc=$?
echo "${0} rc: $rc"

if [ $rc -ne 0 ]
then 
    echo "${0} exiting due to error $rc"
    exit $rc
fi

# now do a full copy including geant4 should we need it e.g. for data areas etc...
# (modified version of copy_to_bluearc was needed)
# it may need more mods to skip copying geant4 work area (or it should be deleted after making the g4 release...)

echo "running copy_to_bluearc"
time ~paterno/p/ruby-1.9.1-p376/bin/ruby src/copy_to_bluearc ${GEANT_RELEASE} ${CMS_RELEASE} \
${LOCAL_WORK_AREA} ${BLUEARC_WORK_AREA} ${CONFIG_FILE} &> \
logs/copy_to_bluearc.log_`date +%Y%m%d_%H%M%S`

rc=$?
echo "${0} rc: $rc"

if [ $rc -ne 0 ]
then 
    echo "${0} exiting due to error $rc"
    exit $rc
fi

# need to run fix tool description after copy again...

echo "running fix_tool_description"
time ruby src/fix_tool_description ${BLUEARC_WORK_AREA} ${GEANT_RELEASE} ${CMS_RELEASE} &> \
logs/fix_tool_description.log_`date +%Y%m%d_%H%M%S`

rc=$?
echo "${0} rc: $rc"

if [ $rc -ne 0 ]
then 
    echo "${0} exiting due to error $rc"
    exit $rc
fi

# create exp in the db: (with -n would be a dry run)

# this also defines the number of trials per job anf number of jobs (in that order)

echo "running profile_cmsRun"
~paterno/p/ruby-1.9.1-p376/bin/ruby src/profile_cmsRun g4profiling ${GEANT_RELEASE} ${CMS_RELEASE} unmodified ${CONFIG_FILE} 5 20 \
-n -e production  -r ${BLUEARC_WORK_AREA} -o ${BLUEARC_OUTPUT_AREA} &> \
logs/profile_cmsRun.log_`date +%Y%m%d_%H%M%S`

rc=$?
echo "${0} rc: $rc"

if [ $rc -ne 0 ]
then 
    echo "${0} exiting due to error $rc"
    exit $rc
fi

#ssh cmslpc-sl5 'cd ${BLUEARC_OUTPUT_AREA}/exp_41; /opt/condor/bin/condor_submit submit_me'
#Submitting job(s)........
#Logging submit event(s)........
#8 job(s) submitted to cluster 4454.


#ssh cmslpc-sl5 '/opt/condor/bin/condor_q -global 4454'


#-- Schedd: cmslpc15.fnal.gov : <131.225.191.208:52619>
# ID      OWNER            SUBMITTED     RUN_TIME ST PRI SIZE CMD
#4454.0   genser          2/1  12:19   0+00:00:00 I  0   0.0  run_me.sh 0
#4454.1   genser          2/1  12:19   0+00:00:00 I  0   0.0  run_me.sh 1
#4454.2   genser          2/1  12:19   0+00:00:00 I  0   0.0  run_me.sh 2
#4454.3   genser          2/1  12:19   0+00:00:00 I  0   0.0  run_me.sh 3
#4454.4   genser          2/1  12:19   0+00:00:00 I  0   0.0  run_me.sh 4
#4454.5   genser          2/1  12:19   0+00:00:00 I  0   0.0  run_me.sh 5
#4454.6   genser          2/1  12:19   0+00:00:00 I  0   0.0  run_me.sh 6
#4454.7   genser          2/1  12:19   0+00:00:00 I  0   0.0  run_me.sh 7
