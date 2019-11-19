#!/bin/bash

# svn keywords:
# $Rev: 719 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-03-24 16:20:19 -0500 (Thu, 24 Mar 2011) $: Date of last commit

#
# an attempt to automate the scram build step
#

# basically this:

#cd /storage/local/data1/geant4work/g4.9.2.p01_cms_3_3_6/modified/CMSSW_3_3_6/src
#time scramv1 --debug build --verbose -j 16 -k 2>&1 | tee scram_build.log_`date +%Y%m%d_%H%M%S`
#egrep "Error|error:" scram_build.log_20100106_165520 | more

# TODO: Move this to CMS-specific directory, preparing for move out of perfdb.

trap "echo 'Exiting due to user interrupt' && exit" INT

OUR_NODENAME=`uname -n`

if [ ${OUR_NODENAME} != "cmswn1340.fnal.gov" ] && [ ${OUR_NODENAME} != "cmssrv140.fnal.gov" ]
then
   echo This script expects to be run on cmswn1340.fnal.gov or cmssrv140.fnal.gov
   exit 1
fi

if [ $# -ne 1 ]
then
    echo "Wrong number of arguments"
    echo "CMSSW src area (e.g. /storage/local/data1/geant4work/g4.9.2.p01_cms_3_3_6/modified/CMSSW_3_3_6/src)"
    exit 1
fi

HERE=$1
echo "OUR_NODENAME is:      ${OUR_NODENAME}"
echo "HERE is:              ${HERE}"

if pushd ${HERE}
then
   echo We are now in $PWD
else
   echo Failed to move to directory ${HERE}
   exit 1
fi

# Adjust umask so that files are created with group read/write
umask 0002

#-----------------------------------------------------------------------
# Work starts here.
#-----------------------------------------------------------------------

source /uscmst1/prod/sw/cms/bashrc prod
OUR_LOG_FILE=scram_build.log_`date +%Y%m%d_%H%M%S`_$$

echo "Doing scram build, see ${HERE}/${OUR_LOG_FILE}"

scramv1 --debug build --verbose -j 16 -k 2>&1 > ${OUR_LOG_FILE}
#scramv1 --debug build --verbose USER_CXXFLAGS="-g" -j 16 -k 2>&1 > ${OUR_LOG_FILE}

OUR_SCRAM_RETCODE=$?

echo "OUR_SCRAM_RETCODE is:      ${OUR_SCRAM_RETCODE}"

echo "Doing egrep for errors, see: ${HERE}/${OUR_LOG_FILE}"

egrep "Error|error:" ${OUR_LOG_FILE}
EGREP_RETCODE=$?
#seeing errors is bad; hence reverse logic

if  [ ${EGREP_RETCODE} -eq 0 ]
then
    OUR_EGREP_RETCODE=1
else 
    if [ ${EGREP_RETCODE} -eq 2 ]
    then
	OUR_EGREP_RETCODE=2
    else
	OUR_EGREP_RETCODE=0
    fi
fi

echo "EGREP_RETCODE is:          ${EGREP_RETCODE}"
echo "OUR_EGREP_RETCODE is:      ${OUR_EGREP_RETCODE}"

# lets use arithmetic logic $(( )); it returns 1 for true as opposed to [ ]

OUR_FINAL_RETURN_CODE=$(( ( $OUR_SCRAM_RETCODE != 0 ) || ( $OUR_EGREP_RETCODE != 0 ) ))

if [ $OUR_FINAL_RETURN_CODE -ne 0 ]
then
    echo "Errors reported in scram build"
    echo "check: ${HERE}/${OUR_LOG_FILE}"
    exit 1
fi

echo "It looks like scram build was successful"
echo "You may still take a look at: ${HERE}/${OUR_LOG_FILE}"
exit 0
