#!/bin/bash

# svn keywords:
# $Rev: 748 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-08-12 13:09:16 -0500 (Fri, 12 Aug 2011) $: Date of last commit

# TODO: Move this to g4 profiling directory, preparing for move out of perfdb.

trap "echo 'Exiting due to user interrupt' && exit" INT

OUR_NODENAME=`uname -n`

if  [ ${OUR_NODENAME} != "cmssrv140.fnal.gov" ]
then
   echo This script expects to be run on cmssrv140.fnal.gov
   exit 1
fi

if [ $# -ne 2 ]
then
    echo "Wrong number of arguments"
    echo "Must supply GEANT release number (e.g. 9.2.p01) and"
    echo "CMS release number (e.g. 3_0_0_pre10)"
    exit 1
fi

PCMS_AREA="/uscmst1/prod/sw/cms"

if ! type -p scramv1
then
    source ${PCMS_AREA}/bashrc prod
#    export SCRAM_ARCH=slc4_ia32_gcc345
    export SCRAM_ARCH=`scramv1 arch`
fi

GEANT_RELEASE=$1
CMS_RELEASE=$2

echo "${0} called   with $1 $2 $3 $4 $5 $6 $7"

#echo "Geant release is: ${GEANT_RELEASE}"
#echo "CMS release is:  ${CMS_RELEASE}"

#-----------------------------------------------------------------------
# Move to the right directory to do all the work.
#-----------------------------------------------------------------------

if [ ${OUR_NODENAME} = "cmssrv140.fnal.gov" ]
then
    HERE=/storage/local/data1/geant4work
fi

echo "${0} HERE on ${OUR_NODENAME} is ${HERE}"

if pushd ${HERE}
then
   echo We are now in $PWD
else
   echo Failed to move to directory ${HERE}
   exit 1
fi

# finding out CLHEP_BASE_DIR

PCMS_SELECTED_AREA="${PCMS_AREA}/${SCRAM_ARCH}/cms/cmssw/CMSSW_${CMS_RELEASE}/config/toolbox/${SCRAM_ARCH}/tools/selected"

PCLHEP_XML="${PCMS_SELECTED_AREA}/clhep.xml"

#take it from  /uscmst1/prod/sw/cms/slc4_ia32_gcc345/cms/cmssw/CMSSW_3_0_0_pre10/config/toolbox/slc4_ia32_gcc345/tools/selected/clhep.xml
#      <environment name="CLHEP_BASE" default="/uscmst1/prod/sw/cms/slc4_ia32_gcc345/external/clhep/1.9.4.2"/>

if [ ! -f ${PCLHEP_XML} ]
then
    echo "PCLHEP_XML is set to ${PCLHEP_XML}"
    echo "This file does not exist; aborting."
    exit 1
fi

CLHEP_BASE_DIR=`grep $SCRAM_ARCH $PCLHEP_XML | sed -e 's/.*default=//' -e 's/\/>//' -e 's/"//g'`

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
echo "CMS release is:  ${CMS_RELEASE}"
echo "SCRAM_ARCH release is:  ${SCRAM_ARCH}"
echo "CLHEP_BASE_DIR is:  ${CLHEP_BASE_DIR}"


TARBALL="${HERE}/download/geant4.${GEANT_RELEASE}.tar.gz"

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
# Work starts here.
#-----------------------------------------------------------------------

# Make directories
TOPDIR="${HERE}/g4.${GEANT_RELEASE}_cms_${CMS_RELEASE}"
MODIFIED="${TOPDIR}/modified"
UNMODIFIED="${TOPDIR}/unmodified"

if [ -d ${TOPDIR} ]
then
    echo "${TOPDIR} directory already exists, rename it or remove it before continuing"
    echo "Aborting."
    exit 1
fi

#-----------------------------------------------------------------------
# Create the directory structure

echo "Creating ${MODIFIED}/work"
mkdir -p ${MODIFIED}/work

echo "Creating ${UNMODIFIED}/work"
mkdir -p ${UNMODIFIED}/work

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

# we should be able to setup clhep now

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

###cd CMSSW_${CMS_RELEASE}/src

cd ${TOPDIR}

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

echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"

if [ $LD_LIBRARY_PATH ] ; then
    LD_LIBRARY_PATH=${GCC_DIR}/../lib:${LD_LIBRARY_PATH}
else
    LD_LIBRARY_PATH=${GCC_DIR}/../lib
fi

export LD_LIBRARY_PATH

# Modify the Geant4 platform/compiler make file fragment. the -O2 -g should be replaced by modifying the env.sh file or setting G4OPTDEBUG
#sed -i_orig1 -r "s/-O2/-O2 -g/;s?CXX +:= g\+\+?CXX := ${GCC_DIR}/c\+\+?"  ${UNMODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk
sed -i_orig1 -r "s?CXX +:= g\+\+?CXX := ${GCC_DIR}/c\+\+?"  ${UNMODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk
cp ${UNMODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk ${MODIFIED}/geant4.${GEANT_RELEASE}/config/sys/Linux-g++.gmk

# note the copy/paste below...

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

#echo "see the bottom of this very: ${0} script for the next commands to run"
#echo "remember to source <g4version>/(un)modified/env.sh "
#echo "e.g. ${G4INSTALL}/env.sh before doing a build"
#echo "both the unmodified and modified areas have been set up for the build"
#echo "1. run the env.sh script"
#echo "2. run make -j 16"
#echo "3. make global"
#echo "4. run make includes"
#echo "You should be in a  G4INSTALL/source directory e.g. ${G4INSTALL}/source before you run them"

#################exit 0

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

time make -j 16

# This replaces the granular libraries with the global libraries:
echo "printing env "
env
echo "in ${PWD}, starting make global"

time make global

# install all header files
echo "printing env "
env
echo "in ${PWD}, starting make includes"

make includes

echo "CXX is: ${CXX}"
echo "G4WORKDIR is: ${G4WORKDIR}"

echo "in ${PWD} done with make"

echo "removing G4WORKDIR"
if [ -n "${G4WORKDIR}" ] && [ -d "${G4WORKDIR}" ]
then
    rm -rf ${G4WORKDIR}
fi

# now repeat it for UNMODIFIED
# remeber that env.sh unsets many G4 varaibles

export G4INSTALL=${UNMODIFIED}/geant4.${GEANT_RELEASE}
cd ${G4INSTALL}/source


echo "in ${PWD}, sourcing env.sh"

source ../env.sh

### Force G4OPTDEBUG=1
export G4OPTDEBUG=1
echo "printing env "
env

# build all libraries

echo "in ${PWD}, starting make"

time make -j 16

# This replaces the granular libraries with the global libraries:
echo "printing env "
env
echo "in ${PWD}, starting make global"

time make global

# install all header files
echo "printing env "
env
echo "in ${PWD}, starting make includes"

make includes

echo "CXX is: ${CXX}"
echo "G4WORKDIR is: ${G4WORKDIR}"

echo "in ${PWD} done with make"

echo "removing G4WORKDIR"
if [ -n "${G4WORKDIR}" ] && [ -d "${G4WORKDIR}" ]
then
    rm -rf ${G4WORKDIR}
fi

exit
