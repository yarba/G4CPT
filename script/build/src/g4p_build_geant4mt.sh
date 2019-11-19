#!/bin/bash

# svn keywords:
# $Rev: 1 $: Revision of last commit
# $Author: syjun $: Author of last commit
# $Date: 2011-10-19 09:10:28 $: Date of last commit

#-------------------------------------------------------------------------
# CMake version of make_new_standard_geant_release.sh
#-------------------------------------------------------------------------
if [ $# -lt 4 ]; then
  echo -e "\nUsage: g4p_build_geant4mt.sh G4P_PROJECT_DIR G4P_GEANT4_RELEASE G4P_G4DATASETS
        G4P_APPLICATION_NAME [G4P_APPLICATION_RELEASE]" 
  exit 1
fi

PROJECT_DIR=$1
GEANT4_RELEASE=$2
#
# NOTE(Oct.2018, JVY): make it a separate input arg 
#            instead of ${DOWNLOAD_DIR}/g4data
G4DATASETS_DIR=$3
#
APPLICATION_NAME=$4
APPLICATION_RELEASE=$5

DYNAMIC=$6

# NOTE (Oct.2018, JVY): in principle, this can be made an input argument...
#             ... in case we decide to move "download" to /lfstev...
#             ... while building out of /g4/g4p...
#
DOWNLOAD_DIR="${PROJECT_DIR}/download"

#check where ups products are available and set necessary products
#if [ -z "${UPS_DIR}" ] ; then 
#  source /products/setup
#  setup cmake
#  setup gcc v4_8_2 -f Linux64bit+2.6-2.12
#fi
#-----------------------------------------------------------------------
# Check whether the geant4 tarball exists for the selected release
#-----------------------------------------------------------------------

TARBALL="${DOWNLOAD_DIR}/geant4/geant4.${GEANT4_RELEASE}.tar.gz"

if [ ! -f ${TARBALL} ]; then
  echo "... The geant4 tarball, ${TARBALL} does not exist: Aborting ..."
  exit 1
else
  echo "... Using ... ${TARBALL} to build geant4.${GEANT4_RELEASE} ..." 
fi

echo " G4DATASETS_DIR = ${G4DATASETS_DIR} "

#-----------------------------------------------------------------------
# Default options
#-----------------------------------------------------------------------

unset G4P_USE_CLHEP ; G4P_USE_CLHEP=0
#unset G4P_CXX ; G4P_CXX=/cvmfs/fermilab.opensciencegrid.org/products/larsoft/gcc/v6_3_0/Linux64bit+2.6-2.12/bin/g++
#unset G4P_CC  ; G4P_CC=/cvmfs/fermilab.opensciencegrid.org/products/larsoft/gcc/v6_3_0/Linux64bit+2.6-2.12/bin/gcc
#export LD_LIBRARY_PATH=/cvmfs/fermilab.opensciencegrid.org/products/larsoft/gcc/v6_3_0/Linux64bit+2.6-2.12/lib:${LD_LIBRARY_PATH}
#export LD_LIBRARY_PATH=/lib64:${LD_LIBRARY_PATH}
#export PATH=/home/g4p/products/cmake-3.4.0/bin:${PATH}
module load gcc/7.1.0
unset G4P_CXX ; G4P_CXX=/usr/local/gcc-7.1.0/bin/g++
unset G4P_CC  ; G4P_CC=/usr/local/gcc-7.1.0/bin/gcc
#export LD_LIBRARY_PATH=/usr/local/gcc-7.1.0/lib64:/usr/local/gcc-7.1.0/lib:${LD_LIBRARY_PATH}
#export LD_LIBRARY_PATH=/lib64:${LD_LIBRARY_PATH}
# --> migrate --> export PATH=/g4/g4p/products-gcc71/cmake-3.11.1/bin:${PATH}
export PATH=/lfstev/g4p/g4p/products/cmake-3.11.1/bin:${PATH}

#-----------------------------------------------------------------------
# Specific Flags for CMMSSW: Compiler and CLHEP 
#-----------------------------------------------------------------------
if [ x"${APPLICATION_NAME}" = x"cmssw" ]; then

  echo "... cmssw application ... obsolete"
fi

#-----------------------------------------------------------------------
# Create the directory structure
#-----------------------------------------------------------------------
umask 0002

WORK_DIR="${PROJECT_DIR}/build/g4mt.${GEANT4_RELEASE}"

if [ -d ${WORK_DIR} ] ; then
  echo "... Geant4, ${WORK_DIR} already exists! ..."
  echo "... Do you want to overwrite the directory? ..."
  echo "... Answer [no|yes] ..."
  unset confirm; read confirm
  if [ x"$confirm" = x"yes" ]; then 
    echo "... Removing ${WORK_DIR} and creating a new one ... "
    rm -rf ${WORK_DIR}
  else
    echo "... Creating a new geant4 cancelled ... "
    exit 1
  fi  
fi

BUILD_DIR="${WORK_DIR}/geant4mt.${GEANT4_RELEASE}-build"
INSTALL_DIR="${WORK_DIR}/geant4mt.${GEANT4_RELEASE}"

echo "... Creating Build Directory, ${BUILD_DIR} ..."
mkdir -p ${BUILD_DIR}

pushd ${WORK_DIR}
tar zxf ${TARBALL}
mv geant4.${GEANT4_RELEASE} geant4mt.${GEANT4_RELEASE}

cd ${INSTALL_DIR}

#mkdir -p data
#
#cd data
#for F in ${DOWNLOAD_DIR}/g4data/*.tar.gz ; do
#    tar zxf $F
#done

#link to the geant4 data files
# --> migrate --> ln -s ${DOWNLOAD_DIR}/g4data data
echo " making a soft link to ${G4DATASETS_DIR} "
ln -s ${G4DATASETS_DIR} data

cd ${BUILD_DIR}

#-----------------------------------------------------------------------
# configure with cmake
#-----------------------------------------------------------------------
#FLAG_TESTR="-O3 -g -fno-omit-frame-pointer -DG4FPE_DEBUG -DG4DEBUG_VERBOSE" 
XERCESC_DIR=/home/g4p/products/xerces-c-3.1.1
export XERCESC_DIR

cmake -DCMAKE_CXX_COMPILER=${G4P_CXX} \
      -DCMAKE_C_COMPILER=${G4P_CC} \
      -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-O3 -g -fno-omit-frame-pointer -Winline" \
      -DGEANT4_USE_SYSTEM_CLHEP=${G4P_USE_CLHEP} \
      -DGEANT4_INSTALL_DATA=0 \
      -DGEANT4_USE_GDML=ON \
      -DGEANT4_BUILD_MULTITHREADED=ON \
      -DGEANT4_USE_OPENGL_X11=ON \
      -DXERCESC_ROOT_DIR=${XERCESC_DIR} \
      ${INSTALL_DIR}/source ${INSTALL_DIR}
#      -DCMAKE_CXX_FLAGS_TESTRELEASE=${FLAG_TESTR} \
#      -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG" \
#      -DCMAKE_C_FLAGS_RELWITHDEBINFO="-O3 -g -fno-omit-frame-pointer" \
#      -DCLHEP_CONFIG_EXECUTABLE=${CLHEP_ROOT_DIR}/bin/clhep-config \
#      -DX11_INC_SEARCH_PATH=/usr/lib64 \
#      -DX11_LIB_SEARCH_PATH=/usr/include \
#      -DOPENGL_X11_INCLUDE_DIR=/usr/include/X11 \
#      -DXERCESC_INCLUDE_DIR=${XERCESC_DIR}/include \
#      -DXERCESC_LIBRARY=${XERCESC_DIR}/lib \

#-----------------------------------------------------------------------
# build and install - parallel compilation
#-----------------------------------------------------------------------
make -j8
#make -j8 VERBOSE=1
make install

# Change permissions for everything to group read/write
pushd ${WORK_DIR}
echo "... Changing permissions under ${WORK_DIR} ..."
chmod -R g+rw ${WORK_DIR}
