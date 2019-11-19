#!/bin/bash

# svn keywords:
# $Rev: 1 $: Revision of last commit
# $Author: syjun $: Author of last commit
# $Date: 2011-10-19 09:10:28 $: Date of last commit

#------------------------------------------------------------------------------
# CMake version of make_new_standard_executable.sh
#------------------------------------------------------------------------------
if [ $# -lt 3 ]; then
  echo "Usage: g4p_build_application.sh G4P_PROJECT_DIR G4P_GEANT4_RELEASE \
    G4P_APPLICATION_NAME [G4P_APPLICATION_RELREASE] [G4P_APPLICATION_CVSTAG]" 
  exit 1
fi

PROJECT_DIR=$1
GEANT4_RELEASE=$2
APPLICATION_NAME=$3

#optional arguments for cmssw
APPLICATION_RELEASE=$4
APPLICATION_CVSTAG=$5

#check where ups products are available and set necessary products
#if [ -z "${UPS_DIR}" ] ; then 
#  source /products/setup
#  setup cmake
#  setup gcc v4_8_2 -f Linux64bit+2.6-2.12
#fi

DOWNLOAD_DIR="${PROJECT_DIR}/download"
COMPILER_DIR="/usr/local/gcc-4.9.2"

export CXX=${COMPILER_DIR}/bin/g++
export CC=${COMPILER_DIR}/bin/gcc
export LD_LIBRARY_PATH=${COMPILER_DIR}/lib:${COMPILER_DIR}/lib64:${LD_LIBRARY_PATH}
#export PATH=/home/syjun/products.gpu/cmake-2.8.11.2/bin:${PATH}

unset BUILD_BASE ; unset APPLICATION_DIR
GEANT4_BASE=${PROJECT_DIR}/build/g4.${GEANT4_RELEASE}
APPLICATION_DIR=${GEANT4_BASE}/${APPLICATION_NAME}

unset BUILD_DIR;
BUILD_DIR=${GEANT4_BASE}/geant4.${GEANT4_RELEASE}-build

if [ x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then
  GEANT4_BASE=${PROJECT_DIR}/build/g4mt.${GEANT4_RELEASE}
  BUILD_DIR=${GEANT4_BASE}/geant4mt.${GEANT4_RELEASE}-build
  APPLICATION_DIR=${GEANT4_BASE}/${APPLICATION_NAME}
fi

if [ -d ${APPLICATION_DIR} ] ; then
  echo "... Application, ${APPLICATION_DIR} already exists! ..."
  echo "... Do you want to overwrite the directory? ..."
  echo "... Answer [no|yes] ..."
  unset confirm; read confirm
  if [ x"$confirm" = x"yes" ]; then 
    echo "... Removing the application and creating a new one ... "
    rm -rf ${APPLICATION_DIR}
  else
    echo "... Creating a new application cancelled ... "
    exit 1
  fi
fi

pushd ${GEANT4_BASE}

if [ x"${APPLICATION_RELEASE}" = x"mt" ]; then
  export LD_LIBRARY_PATH=${GEANT4_BASE}/geant4.${GEANT4_RELEASE}/lib:${LD_LIBRARY_PATH}
fi

if [ x"${APPLICATION_NAME}" = x"SimplifiedCalo" -o \
     x"${APPLICATION_NAME}" = x"cmsExp" -o \
     x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then

    tar -xzf ${DOWNLOAD_DIR}/application/${APPLICATION_NAME}.tgz 
    mkdir -p ${APPLICATION_NAME}/bin
    cd ${APPLICATION_NAME}/bin

  #build with IGPROF service and GDML
  XERCESC_DIR=/home/g4p/products/xerces-c-3.1.1
  export XERCESC_DIR
#  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${XERCESC_DIR}/lib
#  export DG4LIB_BUILD_GDML=1

  if [ x"${APPLICATION_NAME}" = x"SimplifiedCalo" ]; then
      cmake -DGeant4_DIR=${BUILD_DIR} .. 
  else
      cmake -DGeant4_DIR=${BUILD_DIR} -DProject=${APPLICATION_NAME} .. 
  fi

#        -DG4LIB_BUILD_GDML=ON \
#        -DXERCESC_INCLUDE_DIR=${XERCESC_DIR}/include \
#        -DXERCESC_LIBRARY=${XERCESC_DIR}/lib \
#        -Dxercesc_DIR=${XERCESC_DIR}/lib \
#        -DXERCESC_ROOT_DIR=${XERCESC_DIR} \

  make -j4

  #CMake maual setup to link geant4 data: add locations of data to env file
  env_sh=${GEANT4_BASE}/${APPLICATION_NAME}/setenv.sh
  echo "#CMake manual setup to link geant4 data" >> ${env_sh} 
  popd
  echo "export G4P_G4DIR=${GEANT4_BASE}/geant4.${GEANT4_RELEASE}" >> ${env_sh}
  grep "path-to-data" ./g4p.init | \
    awk '{split($0,aa,"/"); print aa["1"]" "aa["2"]}' | \
    awk '{print "export "$3"=${G4P_G4DIR}/data/"$5}' >> ${env_sh}

  #add geant4 lib and application bin to LD_LIBRARY_PATH and PATH, respectively
  echo -e "\nexport LD_LIBRARY_PATH=\${G4P_G4DIR}/lib:\${LD_LIBRARY_PATH}" >> ${env_sh} 
  echo "export LD_LIBRARY_PATH=${COMPILER_DIR}/lib:\${LD_LIBRARY_PATH}" >> ${env_sh} 
  echo "export LD_LIBRARY_PATH=${COMPILER_DIR}/lib64:\${LD_LIBRARY_PATH}" >> ${env_sh} 

#  echo -e "\nPATH=\${PATH}:${APPLICATION_DIR}/bin" >> ${env_sh}
#  echo -e "export PATH" >> ${env_sh}

  #set the default gdml file and magnetic field map for cmsExp 
  if [ x"${APPLICATION_NAME}" = x"cmsExp" -o x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then
    echo "export CMSEXP_GDML=${APPLICATION_DIR}/gdml/cmsExp_calo.gdml" \
          >> ${env_sh} 
    echo "export CMSEXP_BFIELD_MAP=${APPLICATION_DIR}/cmsExp.mag.3_8T" \
          >> ${env_sh} 
    echo "export http_proxy=http://192.168.76.79:3128" >> ${env_sh}
  fi
fi

if [ x"${APPLICATION_NAME}" = x"cmssw" ]; then

  echo "... Building CMSSW_${APPLICATION_RELEASE} with Geant4.${GEANT4_RELEASE} ..."

#  CLHEP_DIR="${DOWNLOAD_DIR}/clhep/${CLHEP_RELEASE}"
#  if [ ! -d  ${CLHEP_DIR} ]; then
#       "... ${CLHEP_DIR} does not exist; Aborting ..." ;  exit 1
#  fi

  #setup cmsenv
  if [ -z "${CMS_PATH}" ] ; then 
    source /uscmst1/prod/sw/cms/shrc prod
  fi

  if ! scramv1 project CMSSW CMSSW_${APPLICATION_RELEASE}
  then
    echo "scramv1 command failed to create CMS work area; aborting."
    exit 1    
  fi

  cd ${APPLICATION_DIR}/src

  #use cvs anonymous access without kserver_init

  CVSROOT=:pserver:anonymous:98passwd@cmscvs.cern.ch:/cvs_server/repositories/CMSSW
  echo "doing cvs login" 
  cvs login 

  #checkout packages  

  for package in FWCore/Services SimG4Core SimG4CMS ; do
    cvs -z5 checkout -r CMSSW_${APPLICATION_CVSTAG} $package
    if [ ! -d  ${APPLICATION_DIR}/src/$package ]; then
       "... CVS Checkout $package failed; Aborting ..." ;  exit 1
    fi
  done
  # cvs -z5 checkout Validation/Geant4Releases
  #according to Krzysztof, temporarily need a patch for PhysicsLists by Sunanda
  cvs -z5 checkout -r V01-06-03 SimG4Core/PhysicsLists

  #fix configuration to build cmssw with the geant4 built for profiling

  echo -e "... Fixing CMSSW configuration files  ..."

  #-1) config/BuildFile.xml: no longer setting up the cxx (do nothing)

  cmstooldir=${APPLICATION_DIR}/config/toolbox/${SCRAM_ARCH}/tools/selected

  # 0) $cmstooldir/cxxcompiler.xml: has the proper opt level (-O2) (do nothing)
  # 1) $cmstooldir/geant4.xml: fix version         

  g4_xml=$cmstooldir/geant4.xml
  cmsg4version=`grep version ${g4_xml} |awk '{split($3,aa,"\""); print aa["2"]}'`
  sed -i_org1 "s/version=\"${cmsg4version}\"/version=\"${GEANT4_RELEASE}\"/" ${g4_xml}

  # 2) $cmstooldir/geant4core.xml: fix version, GEANT4CORE_BASE and INCLUDE 

  g4core_xml=$cmstooldir/geant4core.xml
  cmsg4version=`grep version ${g4core_xml} |awk '{split($3,aa,"\""); print aa["2"]}'`
  cmsg4dir=`grep uscmst1 ${g4core_xml} |awk '{split($3,bb,"\""); print bb["2"]}'`

  sed -i_org1 "s/version=\"${cmsg4version}\"/version=\"${GEANT4_RELEASE}\"/" ${g4core_xml}
  sed -i_org2 "s%${cmsg4dir}%${GEANT4_BASE}/geant4.${GEANT4_RELEASE}%"       ${g4core_xml}
  sed -i_org3 "s%GEANT4CORE_BASE/include%GEANT4CORE_BASE/include/Geant4%"    ${g4core_xml}

  # 3) $cmstooldir/clhep.xml: fix version and CLHEP_BASE
#  clhep_xml=$cmstooldir/clhep.xml
#  clhepversion=`grep version ${clhep_xml} | awk '{split($3,aa,"\""); print aa["2"]}'`
#  clhepdir=`grep CLHEP_BASE ${clhep_xml} |\
#    grep -v \\$CLHEP_BASE |awk '{split($3,bb,"\""); print bb["2"]}'`

#  sed -i_org1 "s/version=\"${clhepversion}\"/version=\"${CLHEP_RELEASE}\"/" ${clhep_xml}
#  sed -i_org2 "s%${clhepdir}%${CLHEP_DIR}%" ${clhep_xml}

  # 4) $cmstooldir/clhepheader.xml: fix version and CLHEPHEADER_BASE 

#  clhepheader_xml=$cmstooldir/clhepheader.xml
#  clhepheaderdir=`grep CLHEPHEADER_BASE ${clhepheader_xml} |\
#    grep -v \\$CLHEPHEADER_BASE  |awk '{split($3,bb,"\""); print bb["2"]}'`

#  sed -i_org1 "s/version=\"${clhepversion}\"/version=\"${CLHEP_RELEASE}\"/" ${clhepheader_xml}
#  sed -i_org2 "s%${clhepheaderdir}%${CLHEP_DIR}%" ${clhepheader_xml}

  # 5) $cmstooldir/geant4data.xml: point geant4 data to local
 
  g4data_xml=$cmstooldir/geant4data.xml

  popd

  idx=0
  for g4data in GEANT4DATA_BASE G4LEDATA G4NEUTRONXS G4NEUTRONHPDATA \
                G4LEVELGAMMADATA G4RADIOACTIVEDATA 
  do
     cmsg4data=`grep ${g4data} ${g4data_xml} |awk '{split($3,aa,"\""); print aa["2"]}'`
     g4pg4file=`grep ${g4data} ./g4p.init |awk '{split($4,aa,"/"); print aa["2"] }'`
     g4pg4data="${GEANT4_BASE}/geant4.${GEANT4_RELEASE}/data/${g4pg4file}"

     idx=`expr $idx + 1`     
     sed -i_org${idx} "s%${cmsg4data}%${g4pg4data}%" ${g4data_xml}
  done

  pushd ${APPLICATION_DIR}/src

  # 6) update changes for geant4
#  for cms_xml in geant4 geant4core geant4data clhep clhepheader
  for cms_xml in geant4 geant4core geant4data
  do
    scramv1 setup ${cms_xml} && scramv1 build ToolUpdated_${cms_xml}
  done

  #build cmssw
  scramv1 --debug build --verbose -j 16 -k

  #check whether scramv build is succefully finished

fi

pushd ${APPLICATION_DIR}
echo Changing permissions under ${APPLICATION_DIR}
chmod -R g+rw ${APPLICATION_DIR}
