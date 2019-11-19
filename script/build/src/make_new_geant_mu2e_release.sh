#!/bin/bash

# svn keywords:
# $Rev: 742 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-07-14 14:10:53 -0500 (Thu, 14 Jul 2011) $: Date of last commit

# a version of geant4 build script to work in the mu2e environment

trap "echo 'Exiting due to user interrupt' && exit" INT

OUR_NODENAME=`uname -n`

if  [ ${OUR_NODENAME} != "mu2egpvm02.fnal.gov" ]
then
   echo This script expects to be run on mu2egpvm02.fnal.gov
   exit 1
fi

if [ $# -ne 2 ]
then
    echo "Wrong number of arguments"
    echo "Must supply GEANT release number (e.g. 9.2.p01) and"
    echo "MU2E_RELEASE (e.g. v1_0_9)"
    exit 1
fi

GEANT_RELEASE=$1
MU2E_RELEASE=$2

echo "${0} called   with $1 $2 $3 $4 $5 $6 $7"

#echo "Geant release is: ${GEANT_RELEASE}"
#echo "MU2E release is:  ${MU2E_RELEASE}"


#geant4 v4_9_4_p01 -f Linux64bit+2.6-2.5 -z /grid/fermiapp/products/mu2e/artexternals -q gcc45
#|__clhep v2_1_0_1 -f Linux64bit+2.6-2.5 -z /grid/fermiapp/products/mu2e/artexternals -q gcc45
#|  |__gcc v4_5_1 -f Linux64bit+2.6-2.5 -z /grid/fermiapp/products/mu2e/artexternals
#|__xerces_c v3_1_1 -f Linux64bit+2.6-2.5 -z /grid/fermiapp/products/mu2e/artexternals -q gcc45



#-----------------------------------------------------------------------
# Move to the right directory to do all the work.
#-----------------------------------------------------------------------

if [ ${OUR_NODENAME} = "mu2egpvm02.fnal.gov" ]
then
#    HERE="/scratch/mu2e/users/genser/geant4work"
# scratch was mounted noexec...
#    HERE="/grid/fermiapp/mu2e/users/genser/geant4work"
    HERE="/mu2e/app/users/genser/geant4work"
    DOWNLOAD="/grid/data/mu2e/users/genser/geant4work"
fi

echo "${0} HERE on ${OUR_NODENAME} is ${HERE}"
echo "${0} DOWNLOAD on ${OUR_NODENAME} is ${DOWNLOAD}"

if pushd ${HERE}
then
   echo We are now in $PWD
else
   echo Failed to move to directory ${HERE}
   exit 1
fi

# Make directories
TOPDIR="${HERE}/g4.${GEANT_RELEASE}_mu2e_${MU2E_RELEASE}"
UNMODIFIED="${TOPDIR}/unmodified"

if [ -d ${TOPDIR} ]
then
    echo "${TOPDIR} directory already exists, rename it or remove it before continuing"
    echo "Aborting."
    exit 1
fi


#-----------------------------------------------------------------------
# Create the directory structure

echo "Creating ${UNMODIFIED}/work"
mkdir -p ${UNMODIFIED}/work

if ! source /grid/fermiapp/products/mu2e/setupmu2e-art.sh
then
    echo "source command failed to setup art environment"
    exit 1    
fi

cd ${UNMODIFIED}

cvs co -P -r ${MU2E_RELEASE} Offline/setup.sh
cvs co -P -r ${MU2E_RELEASE} Offline/bin
cd Offline

echo "UNMODIFIED is: ${UNMODIFIED}"
cd ${UNMODIFIED}/Offline
if ! source setup.sh
then
    echo "source command failed to setup MU2E"
    exit 1    
fi

WANTED_CLHEP_VERSION=${CLHEP_VERSION}
UNWANTED_GEANT4_VERSION=${GEANT4_VERSION}
unsetup geant4 ${UNWANTED_GEANT4_VERSION} -q gcc45
setup clhep $WANTED_CLHEP_VERSION -q gcc45
# the above also sets up gcc

# checking CLHEP_BASE_DIR

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
echo "MU2E release is:  ${MU2E_RELEASE}"
echo "CLHEP_BASE_DIR is:  ${CLHEP_BASE_DIR}"

TARBALL="${DOWNLOAD}/download/geant4.${GEANT_RELEASE}.tar.gz"

if [ ! -f ${TARBALL} ]
then
    echo "TARBALL is set to ${TARBALL}"
    echo "This file does not exist; aborting."
    exit 1
fi

# Adjust umask to that files are created with group read/write
umask 0002

#echo "debug exit"
#exit 11


#-----------------------------------------------------------------------
echo "In ${UNMODIFIED}, untarring ${TARBALL}"
pushd ${UNMODIFIED}
tar zxf ${TARBALL}
cd geant4.${GEANT_RELEASE}
mkdir -p data
cd data
for F in ${DOWNLOAD}/download/*.tar.gz
  do
    if [ ${F} != ${DOWNLOAD}/download/geant4.${GEANT_RELEASE}.tar.gz ]
    then
       tar zxf $F
    fi
  done
popd

#echo "debug exit"
#exit 12

# Modify the Geant4 platform/compiler make file fragment. the -O2 -g should be replaced by modifying the env.sh file or setting G4OPTDEBUG
sed -i_orig0 -r "s/ -g/ -g -O3 -fno-omit-frame-pointer/"  ${UNMODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk
sed -i_orig1 -r "s/-O2/-O3/"  ${UNMODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk
#sed -i_orig2 -r "s?CXX +:= g\+\+?CXX := ${GCC_DIR}/c\+\+?"  ${UNMODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk
#cp ${UNMODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk ${MODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk

#-----------------------------------------------------------------------
# Build the unmodified source
echo "About to setup up build of the unmodified Geant4 source"
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
#echo "export CXX=${CXX}"

# we force global/shared libs here

sed -i_orig1 "s/^g4conf=''/#g4conf/;s/^g4clhep_base_dir=''/#g4clhep_base_dir/" Configure

sed -i_orig2 's/^CONFIG=true/CONFIG=true ; abssrc=${G4INSTALL}/' Configure
sed -i_orig3 "s/^g4lib_build_shared=''/g4lib_build_shared='y'/;s/^g4lib_use_shared=''/g4lib_use_shared='y'/" Configure

sed -i_orig4 "s/^g4lib_use_granular=''/g4lib_use_granular='n'/" Configure
sed -i_orig5 "s/^g4lib_use_granular='y'/g4lib_use_granular='n'/" Configure

sed -i_orig6 "s/^g4global=''/g4global='y'/" Configure
sed -i_orig7 "s/^g4global='n'/g4global='y'/" Configure

sed -i_orig8 "s/^g4granular=''/g4granular='n'/" Configure
sed -i_orig9 "s/^g4granular='y'/g4granular='n'/" Configure

sed -i_orig10 "s/^g4vis_use_openglx=''/g4vis_use_openglx='y'/" Configure
sed -i_orig11 "s/^g4vis_use_openglx='n'/g4vis_use_openglx='y'/" Configure

sed -i_orig11 "s/^g4vis_build_openglx_driver=''/g4vis_build_openglx_driver='y'/" Configure
sed -i_orig12 "s/^g4vis_build_openglx_driver='n'/g4vis_build_openglx_driver='y'/" Configure

sed -i_orig13 "s/^g4w_use_g3tog4=''/g4w_use_g3tog4='y'/" Configure
sed -i_orig14 "s/^g4w_use_g3tog4='n'/g4w_use_g3tog4='y'/" Configure

sed -i_orig15 "s/^g4wlib_build_g3tog4=''/g4wlib_build_g3tog4='y'/" Configure
sed -i_orig16 "s/^g4wlib_build_g3tog4='n'/g4wlib_build_g3tog4='y'/" Configure

sed -i_orig17 "s/^g4clhep_internal=''/g4clhep_internal='n'/" Configure
sed -i_orig18 "s/^g4clhep_internal='y'/g4clhep_internal='n'/" Configure

# first generate the config.sh script needed for the build

echo "In ${PWD}, after modifying Configure before running it"

./Configure -build -dE
# next generate the env.sh script that we need to source
./Configure -build -dErS

ENVFILE=${G4INSTALL}/.config/bin/Linux-g++/env.sh
if [ -f ${ENVFILE} ]
then
 cp ${ENVFILE} ${G4INSTALL}
 # Now fix the env.sh file, which contains a strange value for
 # G4WORKDIR The following replaces the forward slash in the
 # environment variable with an escaped forward slash, so that it can
 # be used in the second sed call.
 TEMP_G4WORKDIR=`echo $G4WORKDIR | sed 's/\//\\\\\//g'`
 sed -i_orig1 "s/# G4WORKDIR/G4WORKDIR=${TEMP_G4WORKDIR}/"  env.sh
fi

#echo "see the bottom of this very: ${0} script for the next commands to run"
#echo "remember to source <g4version>/(un)modified/env.sh "
#echo "e.g. ${G4INSTALL}/env.sh before doing a build"
#echo "both the unmodified and modified areas have been set up for the build"
#echo "1. run the env.sh script"
#echo "2. run make -j 8"
#echo "3. make global"
#echo "4. run make includes"
#echo "You should be in a  G4INSTALL/source directory e.g. ${G4INSTALL}/source before you run them"

# exit 0

#-----------------------------------------------------------------------
# The following is not executed if the exit command above is not commented out
#-----------------------------------------------------------------------

echo "in ${PWD}"

cd source

echo "in ${PWD}, sourcing env.sh"

source ../env.sh

### Force G4OPTDEBUG=1
export G4OPTDEBUG=1
echo "printing env "
env

# build all libraries

echo "in ${PWD}, starting make"

time make -j 8

# This replaces the granular libraries with the global libraries:
echo "printing env "
env
echo "in ${PWD}, starting make global"

time make global

# install all header files
echo "printing env "
env
echo "in ${PWD}, starting make includes"

time make -j 8 includes

echo "CXX is: ${CXX}"
echo g++ `which g++`
echo "G4WORKDIR is: ${G4WORKDIR}"

echo "in ${PWD} done with make"

#echo "Not removing G4WORKDIR"
if [ -n "${G4WORKDIR}" ] && [ -d "${G4WORKDIR}" ]
then
    rm -rf ${G4WORKDIR}
fi

exit

# we now need to modify the setup script to setup our g4 and then build mu2e etc...
