#!/bin/bash

# svn keywords:
# $Rev: 714 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-03-24 15:10:28 -0500 (Thu, 24 Mar 2011) $: Date of last commit

# TODO: Move this to profiling-specific directory, preparing for move out of perfdb.

trap "echo 'Exiting due to user interrupt' && exit" INT

OUR_NODENAME=`uname -n`

if [ ${OUR_NODENAME} != "cmssrv140.fnal.gov" ]
then
   echo This script expects to be run on cmssrv140.fnal.gov
   exit 1
fi

if [ $# -ne 3 ]
then
    echo "Wrong number of arguments"
    echo "Must supply Executable name (e.g. Simplifiedcalo)"
    echo "and GEANT release number (e.g. 9.4.p01)"
    echo "and CLHEP release number (e.g. 2.1.0.1)"
    exit 1
fi

EXECUTABLE=$1
GEANT_RELEASE=$2
CLHEP_RELEASE=$3

echo "${0} called with $1 $2 $3 $4 $5 $6 $7"

#echo "Executable    is: ${EXECUTABLE}"
#echo "Geant release is: ${GEANT_RELEASE}"
#echo "CLHEP release is: ${CLHEP_RELEASE}"

#-----------------------------------------------------------------------
# Move to the right directory to do all the work.
#-----------------------------------------------------------------------

if [ ${OUR_NODENAME} = "cmssrv140.fnal.gov" ]
then
    HERE=/storage/local/data1/geant4work
fi

if pushd ${HERE}
then
   echo We are now in $PWD
else
   echo Failed to move to directory ${HERE}
   exit 1
fi

# setting CLHEP_BASE_DIR

CLHEP_BASE_DIR="${HERE}/clhep/${CLHEP_RELEASE}"

echo "CLHEP_BASE_DIR is set to ${CLHEP_BASE_DIR}"

if [ ! -d ${CLHEP_BASE_DIR} ]
then
    echo "CLHEP_BASE_DIR is set to ${CLHEP_BASE_DIR}"
    echo "This directory does not exist; aborting."
    exit 1
fi

PCLHEP_SO=${CLHEP_BASE_DIR}/lib/libCLHEP.so
if [ ! -f ${PCLHEP_SO} ]
then
    echo "PCLHEP_SO is set to ${PCLHEP_SO}"
    echo "This file does not exist; aborting."
    exit 1
fi

echo "Geant release is: ${GEANT_RELEASE}"
echo "CLHEP_BASE_DIR is: ${CLHEP_BASE_DIR}"

# Adjust umask to that files are created with group read/write
umask 0002

#echo "debug exit"
#exit 11

# Check directories

TMPWORKDIR="${HERE}/g4.${GEANT_RELEASE}/unmodified/work"

if [ ! -d ${TMPWORKDIR} ]
then
    if mkdir ${TMPWORKDIR}
    then
	echo "${TMPWORKDIR} directory created"
    else 
	echo "${TMPWORKDIR} directory does not exists and could not be created"
	echo "Aborting."
	exit 1
    fi
fi

#-----------------------------------------------------------------------
# Work starts here.
#-----------------------------------------------------------------------


cd $TMPWORKDIR
# check if SimplifiedCalo exists, if it does not quit

#if scp genser@ncdf173:/scratch/genser/geant/tarballsToRun/${EXECUTABLE}.tgz ./
TARBALL="${HERE}/download/${EXECUTABLE}.tgz"
if [ -f ${TARBALL} ]
then
   echo Copied ${EXECUTABLE}.tgz to $PWD
   cp ${TARBALL} ${PWD}/${EXECUTABLE}.tgz
else
   echo Failed to copy ${EXECUTABLE}.tgz to $PWD
   exit 1
fi

tar xzf ${EXECUTABLE}.tgz && rm -f ${EXECUTABLE}.tgz

export G4WORKDIR=$TMPWORKDIR/${EXECUTABLE}
export G4OPTDEBUG=1
source $G4WORKDIR/../../geant4.${GEANT_RELEASE}/env.sh
cd $G4WORKDIR
make -j 4

# Change permissions for everything to group read/write
echo Changing permissions under ${TMPWORKDIR}
chmod -R g+rw ${TMPWORKDIR}

exit
