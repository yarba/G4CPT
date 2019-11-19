#!/bin/bash

# svn keywords:
# $Rev: 749 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-08-12 13:10:43 -0500 (Fri, 12 Aug 2011) $: Date of last commit

#
# an attempt to split the original make_new_release.sh
# into the geant4 and cmssw part (this is the cmssw part)
#

# TODO: Move this to CMS-specific directory, preparing for move out of perfdb.

trap "echo 'Exiting due to user interrupt' && exit" INT

OUR_NODENAME=`uname -n`

if [ ${OUR_NODENAME} != "cmssrv140.fnal.gov" ]
then
   echo This script expects to be run on cmssrv140.fnal.gov
   exit 1
fi

if [ $# -lt 2 ]
then
    echo "Wrong number of arguments"
    echo "Must supply GEANT release number (e.g. 9.2.p01) and"
    echo "CMS release number (e.g. 3_0_0_pre10)"
    echo "CMS CVS release number if different from the main release"
    exit 1
fi

if ! type -p scramv1
then
    source /uscmst1/prod/sw/cms/bashrc prod
#    export SCRAM_ARCH=slc4_ia32_gcc345
    export SCRAM_ARCH=`scramv1 arch`
fi

GEANT_RELEASE=$1
CMS_RELEASE=$2

if [ ${3:+1} ]
then
    CMS_CVS_RELEASE=$3
else
    CMS_CVS_RELEASE=$CMS_RELEASE
fi

echo "$0 called with   $1, $2, $3"
echo "$0 translated to $GEANT_RELEASE, $CMS_RELEASE, $CMS_CVS_RELEASE"

#-----------------------------------------------------------------------
# Move to the right directory to do all the work.
#-----------------------------------------------------------------------
if [ ${OUR_NODENAME} = "cmswn1340.fnal.gov" ]
then
    HERE=/storage/local/data2/geant4work
else
    HERE=/storage/local/data1/geant4work
fi

if pushd ${HERE}
then
   echo We are now in $PWD
else
   echo Failed to move to directory ${HERE}
   exit 1
fi

# now done in make_new_geant_release
# This path is hardwired because I don't know where it should come
# from.  This should be fixed!
#CLHEP_BASE_DIR=/uscmst1/prod/sw/cms/slc4_ia32_gcc345/external/clhep/1.9.4.2
#
#if [ ! -d ${CLHEP_BASE_DIR} ]
#then
#    echo "CLHEP_BASE_DIR is set to ${CLHEP_BASE_DIR}"
#    echo "This directory does not exist; aborting."
#    exit 1
#fi

echo "Geant release is: ${GEANT_RELEASE}"
echo "CMS reslease is:  ${CMS_RELEASE}"


# Adjust umask to that files are created with group read/write
umask 0002

#-----------------------------------------------------------------------
# Work starts here.
#-----------------------------------------------------------------------

# Verify directories

TOPDIR="${HERE}/g4.${GEANT_RELEASE}_cms_${CMS_RELEASE}"
MODIFIED="${TOPDIR}/modified"
UNMODIFIED="${TOPDIR}/unmodified"

#-----------------------------------------------------------------------
# Verify the directory structure

if [ ! -d ${MODIFIED} ]
then
    echo "Lacking ${MODIFIED}"
    echo "This directory does not exist; aborting."
    exit 1
fi

if [ ! -d ${UNMODIFIED} ]
then
    echo "Lacking ${UNMODIFIED}"
    echo "This directory does not exist; aborting."
    exit 1
fi

# Change permissions for everything to group read/write
echo Changing permissions under ${TOPDIR}
chmod -R g+rw ${TOPDIR}

# Set up the CMS release
echo "UNMODIFIED is: ${UNMODIFIED}"
cd ${UNMODIFIED}
if ! scramv1 project CMSSW CMSSW_${CMS_RELEASE}
then
    echo "scramv1 command failed to create CMS work area; aborting."
    exit 1    
fi

cd CMSSW_${CMS_RELEASE}/src

echo We are now in $PWD

#echo "About to start checkout; this will stall if you forgot to do your kserver_init"

echo "Will try cvs anonymous access"

export CVSROOT=:pserver:anonymous:98passwd@cmscvs.cern.ch:/cvs_server/repositories/CMSSW

echo "doing cvs login" 
cvs login 

if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/FWCore/Services ]
then
    #echo "Will do cvs -z5 checkout -r CMSSW_${CMS_CVS_RELEASE} FWCore/Services"
    cvs -z5 checkout -r CMSSW_${CMS_CVS_RELEASE} FWCore/Services
fi

if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/FWCore/Services ]
then
    echo "Unable to find directory ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/FWCore/Services"
    echo "Checkout of FWCore/Services failed; aborting"
    exit 1
fi

if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/SimG4Core ]
then
    cvs -z5 checkout -r CMSSW_${CMS_CVS_RELEASE} SimG4Core

# the following line with the hardcoded number is per Sunanda, 
# this will need to be recoded once the proof of principle is done

    cvs -z5 checkout -r V01-06-03                SimG4Core/PhysicsLists
    rm -rf SimG4Core/Geant4e
fi
if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/SimG4Core ]
then
    echo "Unable to find directory ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/SimG4Core"
    echo "Checkout of SimG4Core failed; aborting"
    exit 1
fi

if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/SimG4CMS ]
then
    cvs -z5 checkout -r CMSSW_${CMS_CVS_RELEASE} SimG4CMS
fi
if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/SimG4CMS ]
then
    echo "Unable to find directory ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/SimG4CMS"
    echo "Checkout of SimG4CMS failed; aborting"
    exit 1
fi

if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/Validation/Geant4Releases ]
then
    cvs -z5 checkout Validation/Geant4Releases
fi
if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/Validation/Geant4Releases ]
then
    echo "Unable to find directory ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/Validation/Geant4Releases"
    echo "Checkout of Validation/Geant4Releases failed; aborting"
    exit 1
fi

# correct BuildFile.xml & BuildFile.xml.tmpl

cd ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/config

sed -i_orig1 '/flags/ s/-O0/-O2/;/patsubst/ s/-O2/-O0/' BuildFile.xml
#sed -i_orig1 '/flags/ s/-O0/-O2/;/patsubst/ s/-O2/-O0/' BuildFile.xml.tmpl

echo "Copying checked-out CMSSW source code to ${MODIFIED}"
cd ${MODIFIED}

scramv1 project CMSSW CMSSW_${CMS_RELEASE}
cd CMSSW_${CMS_RELEASE}/
cp -r ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/ .
cd ${TOPDIR}

echo "Done with creating CMSSW project areas. You should now run fix_tool_description and do the builds"
exit 0
