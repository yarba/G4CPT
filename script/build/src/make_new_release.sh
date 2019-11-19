#!/bin/bash

# svn keywords:
# $Rev: 604 $: Revision of last commit
# $Author: paterno $: Author of last commit
# $Date: 2010-04-11 15:20:47 -0500 (Sun, 11 Apr 2010) $: Date of last commit

# TODO: Move this to CMS-specific directory, preparing for move out of perfdb.

trap "echo 'Exiting due to user interrupt' && exit" INT

echo This script is replaced by make_new_geant_release.sh and make_new_cmssw_release.sh
exit 1

if [ `uname -n` != "cmswn1340.fnal.gov" ]
then
   echo This script expects to be run on cmswn1340.fnal.gov
   exit 1
fi

if [ $# -ne 2 ]
then
    echo "Wrong number of arguments"
    echo "Must supply GEANT release number (e.g. 9.2.p01) and"
    echo "CMS release number (e.g. 3_0_0_pre10)"
    exit 1
fi

if ! type -p scramv1
then
    source /uscmst1/prod/sw/cms/bashrc prod
    export SCRAM_ARCH=slc4_ia32_gcc345
fi

GEANT_RELEASE=$1
CMS_RELEASE=$2

#-----------------------------------------------------------------------
# Move to the right directory to do all the work.
#-----------------------------------------------------------------------
HERE=/storage/local/data2/geant4work/
if pushd ${HERE}
then
   echo We are now in $PWD
else
   echo Failed to move to directory ${HERE}
   exit 1
fi

# This path is hardwired because I don't know where it should come
# from.  This should be fixed!
CLHEP_BASE_DIR=/uscmst1/prod/sw/cms/slc4_ia32_gcc345/external/clhep/1.9.4.2

if [ ! -d ${CLHEP_BASE_DIR} ]
then
    echo "CLHEP_BASE_DIR is set to ${CLHEP_BASE_DIR}"
    echo "This directory does not exist; aborting."
    exit 1
fi

echo "Geant release is: ${GEANT_RELEASE}"
echo "CMS reslease is:  ${CMS_RELEASE}"


TARBALL="${HERE}/download/geant4.${GEANT_RELEASE}.tar.gz"

if [ ! -f ${TARBALL} ]
then
  TARBALL="${HERE}/download/geant4.${GEANT_RELEASE}.tar.gz"
fi

# Adjust umask to that files are created with group read/write
umask 0002

#-----------------------------------------------------------------------
# Work starts here.
#-----------------------------------------------------------------------

# Make directories
TOPDIR="${HERE}/g4.${GEANT_RELEASE}"
MODIFIED="${TOPDIR}/modified"
UNMODIFIED="${TOPDIR}/unmodified"

#-----------------------------------------------------------------------
# Create the directory structure

echo "Creating ${MODIFIED}/work"
mkdir -p ${MODIFIED}/work

echo "Creating ${UNMODIFIED}/work"
mkdir -p ${UNMODIFIED}/work

#-----------------------------------------------------------------------
# Untar source into unmodified directory
pushd ${MODIFIED}
echo "In ${MODIFIED}, untarring ${TARBALL}"
tar zxf ${TARBALL}
cd geant4.${GEANT_RELEASE}
mkdir -p data
cd data
for F in ${HERE}/download/*.tar.gz
  do
    tar zxf $F
  done
popd

echo "In ${UNMODIFIED}, untarring ${TARBALL}"
pushd ${UNMODIFIED}
tar zxf ${TARBALL}
cd geant4.${GEANT_RELEASE}
mkdir -p data
cd data
for F in ${HERE}/download/*.tar.gz
  do
    tar zxf $F
  done
popd

# Change permissions for everything to group read/write
echo Changing permissions under ${TOPDIR}
chmod -R g+rw ${TOPDIR}

#-----------------------------------------------------------------------
# Note the elegant copy-and-past programming below. This is what
# happens when you let a shell novice type for too long.
#-----------------------------------------------------------------------

# Set up the CMS release
echo "UNMODIFIED is: ${UNMODIFIED}"
cd ${UNMODIFIED}
if ! scramv1 project CMSSW CMSSW_${CMS_RELEASE}
then
    echo "scramv1 command failed to create CMS work area; aborting."
    exit 1    
fi

cd CMSSW_${CMS_RELEASE}/src

#echo "About to start checkout; this will stall if you forgot to do your kserver_init"

echo "Will try anonymous access"

# this should work after: source /uscmst1/prod/sw/cms/bashrc prod
# but does not
#cmscvsroot CMSSW
export CVSROOT=:pserver:anonymous@cmscvs.cern.ch:/cvs_server/repositories/CMSSW

#env | grep CVS

#this does not work either...
#cvs login <<EOF
#98passwd
#EOF

echo "at the prompt type: 98passwd"
cvs login 


if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/FWCore/Services ]
then
    cvs -z5 checkout -r CMSSW_${CMS_RELEASE} FWCore/Services
fi

if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/FWCore/Services ]
then
    echo "Unable to find directory ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/FWCore/Services"
    echo "Checkout of FWCore/Services failed; aborting"
    exit 1
fi

if [ ! -d ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/SimG4Core ]
then
    cvs -z5 checkout -r CMSSW_${CMS_RELEASE} SimG4Core
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
    cvs -z5 checkout -r CMSSW_${CMS_RELEASE} SimG4CMS
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


cd ${TOPDIR}

echo "Copying checked-out CMSSW source code to ${MODIFIED}"
cd ${MODIFIED}
scramv1 project CMSSW CMSSW_${CMS_RELEASE}
cd CMSSW_${CMS_RELEASE}/
cp -r ${UNMODIFIED}/CMSSW_${CMS_RELEASE}/src/ .
cd ${TOPDIR}

echo "Done with creating CMSSW project areas."

# Find out the name of the compiler our CMS release will use. We beat
# on the shell to cough up this information. Don't do this at home,
# kids.
pushd ${UNMODIFIED}
cd CMSSW_${CMS_RELEASE}/
export TMP_ENV=`scramv1 runtime -sh`
export GCC_EXE=`bash -c "eval ${TMP_ENV} type -p gcc"` 2> /dev/null
export GCC_DIR=`dirname ${GCC_EXE}`
popd

if [ "${GCC_DIR}" = '/usr/bin' ]
then
    echo "Setup of CMSSW runtime left us using the system's compiler; this is probably wrong. Aborting."
    exit 1
fi

if [ -z ${GCC_DIR} ]
then
    echo "Setup of CMSSW runtime using the defined release does not work; aborting"
    exit 1
fi

if [ ! -d ${GCC_DIR} ]
then
    echo "GCC_DIR has been defined to be ${GCC_DIR}, but this is not a directory; aborting"
    exit 1
fi

export CXX=${GCC_DIR}/c++

if [ ! -e ${CXX} ]
then
    echo "CXX has been defined to ${CXX}, but this file does not exist; aborting"
    exit 1
fi

# Modify the Geant4 platform/compiler make file fragment.
sed -i -r "s/-O2/-O2 -g/;s?CXX +:= g\+\+?CXX := ${GCC_DIR}/c\+\+?"  ${UNMODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk
cp ${UNMODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk ${MODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk

#-----------------------------------------------------------------------
# Build the unmodified source
echo "About to setup up build the unmodified Geant4 source"
export G4WORKDIR=${UNMODIFIED}/work
export G4INSTALL=${UNMODIFIED}/geant4.${GEANT_RELEASE}
export G4LIB_BUILD_SHARED=1
cd ${G4INSTALL}

echo "in ${G4INSTALL}, starting configure script"
export g4clhep_base_dir=${CLHEP_BASE_DIR}
export g4conf=${G4INSTALL}/config/scripts

echo "export G4WORKDIR=${UNMODIFIED}/work"
echo "export G4INSTALL=${UNMODIFIED}/geant4.${GEANT_RELEASE}"
echo "export G4LIB_BUILD_SHARED=1"
echo "export g4clhep_base_dir=${CLHEP_BASE_DIR}"
echo "export g4conf=${G4INSTALL}/config/scripts"
echo "export CXX=${CXX}"

sed -i_orig1 "s/^g4conf=''/#g4conf/;s/^g4clhep_base_dir=''/#g4clhep_base_dir/" Configure
sed -i_orig2 's/^CONFIG=true/CONFIG=true ; abssrc=${G4INSTALL}/' Configure
sed -i_orig3 "s/^g4lib_build_shared=''/g4lib_build_shared='y'/;s/^g4lib_use_shared=''/g4lib_use_shared='y'/" Configure
sed -i_orig4 "s/^g4lib_use_granular=''/g4lib_use_granular='n'/" Configure
sed -i_orig5 "s/^g4global=''/g4global='y'/" Configure
sed -i_orig6 "s/^g4granular=''/g4granular='n'/" Configure
sed -i_orig7 "s/^g4granular=''/g4granular='n'/" Configure

# first generate the config.sh script needed for the build
./Configure -build -dE
# next generate the env.sh script that we need to source
./Configure -build -dErS

ENVFILE=${G4INSTALL}/.config/bin/Linux-g++/env.sh
if [ -f ${ENVFILE} ]
then
 cp ${ENVFILE} ${G4INSTALL}
 # Now fix the env.sh file, which contains a stupid value for
 # G4WORKDIR The following replaces the forward slash in the
 # environment variable with an escaped forward slash, so that it can
 # be used in the second sed call.
 TEMP_G4WORKDIR=`echo $G4WORKDIR | sed 's/\//\\\\\//g'`
 sed -i_orig1 "s/# G4WORKDIR/G4WORKDIR=${TEMP_G4WORKDIR}/"  env.sh
fi

#-----------------------------------------------------------------------
# Build the modified source
echo "About to setup up build the modified Geant4 source"
export G4WORKDIR=${MODIFIED}/work
export G4INSTALL=${MODIFIED}/geant4.${GEANT_RELEASE}
export G4LIB_BUILD_SHARED=1
cd ${G4INSTALL}

echo "in ${G4INSTALL}, starting configure script"
export g4clhep_base_dir=${CLHEP_BASE_DIR}
export g4conf=${G4INSTALL}/config/scripts

sed -i_orig1 "s/^g4conf=''/#g4conf/;s/^g4clhep_base_dir=''/#g4clhep_base_dir/" Configure
sed -i_orig2 's/^CONFIG=true/CONFIG=true ; abssrc=${G4INSTALL}/' Configure
sed -i_orig3 "s/^g4lib_build_shared=''/g4lib_build_shared='y'/;s/^g4lib_use_shared=''/g4lib_use_shared='y'/" Configure
sed -i_orig4 "s/^g4lib_use_granular=''/g4lib_use_granular='n'/" Configure
sed -i_orig5 "s/^g4global=''/g4global='y'/" Configure
sed -i_orig6 "s/^g4granular=''/g4granular='n'/" Configure
sed -i_orig7 "s/^g4granular=''/g4granular='n'/" Configure

# first generate the config.sh script needed for the build
./Configure -build -dE
# next generate the env.sh script that we need to source
./Configure -build -dErS

ENVFILE=${G4INSTALL}/.config/bin/Linux-g++/env.sh
if [ -f ${ENVFILE} ]
then
 cp ${ENVFILE} ${G4INSTALL}
 # Now fix the env.sh file, which contains a stupid value for
 # G4WORKDIR The following replaces the forward slash in the
 # environment variable with an escaped forward slash, so that it can
 # be used in the second sed call.
 TEMP_G4WORKDIR=`echo $G4WORKDIR | sed 's/\//\\\\\//g'`
 sed -i_orig1 "s/# G4WORKDIR/G4WORKDIR=${TEMP_G4WORKDIR}/"  env.sh
fi


echo "see the bottom of this very: ${0} script for the next commands to run"
echo "remember to source <g4version>/(un)modified/env.sh "
echo "e.g. ${G4INSTALL}/env.sh before doing a build"
echo "both the unmodified and modified areas have been set up for the build"
echo "1. run the env.sh script"
echo "2. run make -j 2"
echo "3. run make includes"
echo "You should be in a  G4INSTALL/source directory e.g. ${G4INSTALL}/source before you run them"
exit 0

#-----------------------------------------------------------------------
# The following is not executed.
#-----------------------------------------------------------------------

echo "in ${G4INSTALL}/source, starting make"

cd source

# build all libraries
make -j 2

# install all header files
make includes

echo "CXX is: ${CXX}"
echo "G4WORKDIR is: ${G4WORKDIR}"

# Modify ${UNMODIFIED}/ ?
# Copy the build to the modified directory
