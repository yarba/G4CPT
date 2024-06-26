#!/bin/bash

# svn keywords:
# $Rev: 1 $: Revision of last commit
# $Author: syjun $: Author of last commit
# $Date: 2011-10-19 09:10:28 $: Date of last commit

#------------------------------------------------------------------------------
# CMake version of make_new_standard_executable.sh
#------------------------------------------------------------------------------
if [ $# -lt 4 ]; then
  echo "Usage: g4p_build_application.sh G4P_PROJECT_DIR  \ 
    G4P_PROJECT_DIR/G4P_BLUEARC_DIR \
    G4P_GEANT4_RELEASE \
    G4P_APPLICATION_NAME [G4P_APPLICATION_RELREASE] [G4P_APPLICATION_CVSTAG]" 
  exit 1
fi

PROJECT_DIR=$1
SUBMIT_RUN_DIR=$2
GEANT4_RELEASE=$3
APPLICATION_NAME=$4

DOWNLOAD_DIR="${PROJECT_DIR}/download"

#
# --> Jan.2021 migration ot WC-IC
#
# --> module load gnu8/8.3.0
# --> module load cmake/3.15.4
#
# provisions for future upgrade on WC-IC...
## module load gnu11/11.3.0
# migration to EL8 and gcc/11.4.0
module load gcc/11.4.0

## module load cmake/3.21.3
# migration to EL8 
module load cmake  # 3.27.3 will be loaded by default

# --> COMPILER_DIR="/opt/ohpc/pub/compiler/gcc/8.3.0"
#
# provisions for future upgrade on WC-IC...
## COMPILER_DIR="/srv/software/gnu11/11.3.0"
# migration to EL8 and gcc/11.4.0
COMPILER_DIR="/srv/software/el8/x86_64/eb/GCCcore/11.4.0"

CFG_DIR="${PWD}/../cfg"
SRC_DIR="${PWD}"

export CXX=${COMPILER_DIR}/bin/g++
export CC=${COMPILER_DIR}/bin/gcc
export LD_LIBRARY_PATH=${COMPILER_DIR}/lib:${COMPILER_DIR}/lib64:${LD_LIBRARY_PATH}

unset BUILD_BASE ; unset APPLICATION_DIR
GEANT4_BASE=${PROJECT_DIR}/build/g4.${GEANT4_RELEASE}

# --> DO NOT migrate --> 
APPLICATION_DIR=${GEANT4_BASE}/${APPLICATION_NAME}

echo "... SUBMIT_RUN_DIR = ${SUBMIT_RUN_DIR} ..."

unset BUILD_DIR;
BUILD_DIR=${GEANT4_BASE}/geant4.${GEANT4_RELEASE}-build

unset GEANT4MT_BASE
unset BUILDMT_BASE

# case Geant4+VecGeom
unset GEANT4VG_BASE
unset BUILDVG_BASE

unset BUILD_DIR_AUX;

if [ x"${APPLICATION_NAME}" = x"cmsExpMT" -o \
     x"${APPLICATION_NAME}" = x"lArTestMT" ]; then

  #copy non-MT version assuming that it is available
  BUILD_DIR_AUX=${BUILD_DIR}

  #re-define envs for MT
  #
  # GEANT4MT_BASE=${PROJECT_DIR}/build/g4mt.${GEANT4_RELEASE}
  # BUILDMT_DIR=${GEANT4MT_BASE}/geant4mt.${GEANT4_RELEASE}-build
  #
  # As of Aug.2021, unify "non-MT" and MT apps under one build
  # since we'll build with MT extension from now on
  #
  GEANT4MT_BASE=${PROJECT_DIR}/build/g4.${GEANT4_RELEASE}
  BUILDMT_DIR=${GEANT4MT_BASE}/geant4.${GEANT4_RELEASE}-build
  #
  # --> DO NOT migrate --> 
  #
  APPLICATION_DIR=${GEANT4MT_BASE}/${APPLICATION_NAME}

fi

if [[ ${APPLICATION_NAME} =~ "VG" ]]; then

  GEANT4VG_BASE=${PROJECT_DIR}/build/g4vg.${GEANT4_RELEASE}
  BUILDVG_DIR=${GEANT4VG_BASE}/geant4vg.${GEANT4_RELEASE}-build
  APPLICATION_DIR=${GEANT4VG_BASE}/${APPLICATION_NAME}

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

if [ x"${APPLICATION_NAME}" = x"cmsExpMT" -o \
     x"${APPLICATION_NAME}" = x"lArTestMT" ]; then
  pushd ${GEANT4MT_BASE}
elif [[ ${APPLICATION_NAME} =~ "VG" ]]; then
  pushd ${GEANT4VG_BASE}
else
  pushd ${GEANT4_BASE}
fi

# --> FIXME !!! Migrate later !!!
# root dependency for lArTest 
if [ x"${APPLICATION_NAME}" = x"lArTest" -o \
     x"${APPLICATION_NAME}" = x"lArTestMT" ]; then
  source /home/g4p/products/root.v6-03-01-GEANT/bin/thisroot.sh
fi

# case Geant4+VecGeom
if [[ ${APPLICATION_NAME} =~ "VG" ]]; then
   
   app_name=${APPLICATION_NAME%%VG*}
   echo " app_name = ${app_name} "
   tar xzf ${DOWNLOAD_DIR}/application/${app_name}.tgz 
   mv ${app_name} ${APPLICATION_NAME}
   mkdir -p ${APPLICATION_NAME}/bin
   cd ${APPLICATION_NAME}/bin

   # Q(JVY): is it even needed for building app ???
   # --> migrate XERCESC_DIR=/home/g4p/products/xerces-c-3.1.1
   #
   # --> Jn.2021 migration to WC-IC
   #
   # --> XERCESC_DIR=/work1/g4p/g4p/products/gcc-8.3.0/XercesC/xerces-c-3.2.3   
   #
   # provisions for future on WC-IC...
   ## XERCESC_DIR=/work1/g4p/g4p/products/gcc-11.3.0/XercesC/xerces-c-3.2.3 
   # migration to EL8 and gcc/11.4.0 
   XERCESC_DIR=/work1/g4p/g4p/products-el8/spack/opt/spack/linux-almalinux8-ivybridge/gcc-11.4.0/xerces-c-3.2.3-zgaruhzlzpjxhvg4kf7nrljpzmz3e64j
   #
   export XERCESC_DIR
   export LD_LIBRARY_PATH=$XERCESC_DIR/lib:${LD_LIBRARY_PATH}

   unset env_sh;

   env_sh=${GEANT4VG_BASE}/${APPLICATION_NAME}/setenv.sh

   # add cvmfs setup to setenv.sh
   #cat ${SRC_DIR}/g4p_setup_cvmfs.sh >> ${env_sh}
   cat ${SRC_DIR}/g4p_setup_gcc.sh >> ${env_sh}
      
   #CMake maual setup to link geant4 data: add locations of data to env file
   echo "#CMake manual setup to link geant4 data" >> ${env_sh} 
   echo "export G4P_G4DIR=${GEANT4VG_BASE}/geant4vg.${GEANT4_RELEASE}" >> ${env_sh}

   cmake -DGeant4_DIR=${BUILDVG_DIR} -DProject=${app_name} .. 
   make -j1

   popd
   grep "path-to-data" ./g4p.init | \
    awk '{split($0,aa,"/"); print aa["1"]" "aa["2"]}' | \
    awk '{print "export "$3"=${G4P_G4DIR}/data/"$5}' >> ${env_sh}

   #add geant4 lib and application bin to LD_LIBRARY_PATH and PATH, respectively
   echo -e "\nexport LD_LIBRARY_PATH=\${G4P_G4DIR}/lib:\${LD_LIBRARY_PATH}" >> ${env_sh} 
   echo "export LD_LIBRARY_PATH=${COMPILER_DIR}/lib:\${LD_LIBRARY_PATH}" >> ${env_sh} 
   echo "export LD_LIBRARY_PATH=${COMPILER_DIR}/lib64:\${LD_LIBRARY_PATH}" >> ${env_sh} 
   echo "export LD_LIBRARY_PATH=${XERCESC_DIR}/lib64:\${LD_LIBRARY_PATH}" >> ${env_sh} 

   #set the default gdml file and magnetic field map for cmsExp 
# --->   if [ x"${APPLICATION_NAME}" = x"cmsExp" -o x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then
   if [[ ${APPLICATION_NAME} =~ "cmsExp" ]]; then
     echo "export G4P_APPLICATION_DIR=${APPLICATION_DIR}" >> ${env_sh}
     echo "export PATH=\${G4P_APPLICATION_DIR}/bin:\${PATH}" >> ${env_sh}     
     echo "export CMSEXP_GDML=\${G4P_APPLICATION_DIR}/cmsExp.gdml" \
          >> ${env_sh} 
     echo "export CMSEXP_BFIELD_MAP=\${G4P_APPLICATION_DIR}/cmsExp.mag.3_8T" \
          >> ${env_sh} 
   fi

fi 

if [ x"${APPLICATION_NAME}" = x"SimplifiedCalo" -o \
     x"${APPLICATION_NAME}" = x"cmsExp" -o \
     x"${APPLICATION_NAME}" = x"lArTest" -o \
     x"${APPLICATION_NAME}" = x"lArTestMT" -o \
     x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then

    tar -xzf ${DOWNLOAD_DIR}/application/${APPLICATION_NAME}.tgz 
    mkdir -p ${APPLICATION_NAME}/bin
    cd ${APPLICATION_NAME}/bin

  #build with IGPROF service and GDML
  # Q(JVY): is it even needed for building app ?
  # --> migrate XERCESC_DIR=/home/g4p/products/xerces-c-3.1.1
  #
  # --> Jan.2021 migration to WC-IC
  #
  # --> XERCESC_DIR=/work1/g4p/g4p/products/gcc-8.3.0/XercesC/xerces-c-3.2.3
  #
  # provisions for future upgrade on WC-IC...
  ## XERCESC_DIR=/work1/g4p/g4p/products/gcc-11.3.0/XercesC/xerces-c-3.2.3
  # migration to EL8 and gcc/11.4.0
  XERCESC_DIR=/work1/g4p/g4p/products-el8/spack/opt/spack/linux-almalinux8-ivybridge/gcc-11.4.0/xerces-c-3.2.3-zgaruhzlzpjxhvg4kf7nrljpzmz3e64j
  export XERCESC_DIR
  export=LD_LIBRARY_PATH=$XERCESC_DIR/lib:${LD_LIBRARY_PATH}

  unset env_sh;

  if [ x"${APPLICATION_NAME}" = x"SimplifiedCalo" ];then
      env_sh=${GEANT4_BASE}/${APPLICATION_NAME}/setenv.sh

      # add cvmfs setup to setenv.sh
      #cat ${SRC_DIR}/g4p_setup_cvmfs.sh >> ${env_sh}
      cat ${SRC_DIR}/g4p_setup_gcc.sh >> ${env_sh}

      #CMake manual setup to link geant4 data: add locations of data to env file
      echo "#CMake manual setup to link geant4 data" >> ${env_sh} 
      echo "export G4P_G4DIR=${GEANT4_BASE}/geant4.${GEANT4_RELEASE}" >> ${env_sh}

      cmake -DGeant4_DIR=${BUILD_DIR} .. 
      make -j1
  elif [ x"${APPLICATION_NAME}" = x"lArTest" ]; then
      env_sh=${GEANT4_BASE}/${APPLICATION_NAME}/setenv.sh

      # add cvmfs setup to setenv.sh
      #cat ${SRC_DIR}/g4p_setup_cvmfs.sh >> ${env_sh}
      cat ${SRC_DIR}/g4p_setup_gcc.sh >> ${env_sh}

      #CMake maual setup to link geant4 data: add locations of data to env file
      echo "#CMake manual setup to link geant4 data" >> ${env_sh} 
      echo "export G4P_G4DIR=${GEANT4_BASE}/geant4.${GEANT4_RELEASE}" >> ${env_sh}

      cmake -DGeant4_DIR=${BUILD_DIR} -DProject=lArTest .. 
      make -j1
  elif [ x"${APPLICATION_NAME}" = x"cmsExp" ]; then
      env_sh=${GEANT4_BASE}/${APPLICATION_NAME}/setenv.sh

      # add cvmfs setup to setenv.sh
      #cat ${SRC_DIR}/g4p_setup_cvmfs.sh >> ${env_sh}
      cat ${SRC_DIR}/g4p_setup_gcc.sh >> ${env_sh}
      
      #CMake maual setup to link geant4 data: add locations of data to env file
      echo "#CMake manual setup to link geant4 data" >> ${env_sh} 
      echo "export G4P_G4DIR=${GEANT4_BASE}/geant4.${GEANT4_RELEASE}" >> ${env_sh}

      cmake -DGeant4_DIR=${BUILD_DIR} -DProject=${APPLICATION_NAME} .. 
      make -j1
  elif [ x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then
      # now the migration story kicks in !
      # --> migrate --> env_sh=${GEANT4MT_BASE}/${APPLICATION_NAME}/setenv.sh
      # ---> ---> env_sh=${APPLICATION_DIR}/setenv.sh
      #
      # create job submit dir under $SUBMIT_RUN_DIR
      #
      # APPLICATION_RUN=${SUBMIT_RUN_DIR}/build/g4mt.${GEANT4_RELEASE}/${APPLICATION_NAME}
      #
      # As of Aug.2021 unify non-MT and MT apps under the same build
      # since we'll be building with MT extension from now on...
      #
      APPLICATION_RUN=${SUBMIT_RUN_DIR}/build/g4.${GEANT4_RELEASE}/${APPLICATION_NAME}
      env_sh=${APPLICATION_RUN}/setenv.sh
      
      # add cvmfs setup to setenv.sh
      #cat ${SRC_DIR}/g4p_setup_cvmfs.sh >> ${env_sh}
      cat ${SRC_DIR}/g4p_setup_gcc.sh >> ${env_sh}

      #CMake manual setup to link geant4 data: add locations of data to env file
      echo "#CMake manual setup to link geant4 data" >> ${env_sh} 
# --> consolidate apps -->      echo "export G4P_G4DIR=${GEANT4MT_BASE}/geant4mt.${GEANT4_RELEASE}" >> ${env_sh}
      echo "export G4P_G4DIR=${GEANT4MT_BASE}/geant4.${GEANT4_RELEASE}" >> ${env_sh}

      echo "...Building ${APPLICATION_NAME} ... with ${BUILDMT_DIR}"
      cmake -DGeant4_DIR=${BUILDMT_DIR} -DProject=cmsExpMT .. 
      make -j1
      
#      echo "...Building cmsExpRMF ... with ${BUILD_DIR_AUX}"
#      cmake -DGeant4_DIR=${BUILDMT_DIR} -DProject=cmsExpRMF -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_STANDARD=17 ..
#      make -j1

      # if APPLICATION_NAME=cmsExpMT, also need to build non-MT version of exe
      # ... NOT any longer since summer 2021...
      #
#      echo "...Building cmsExp ... with ${BUILD_DIR_AUX}"
#      cmake -DGeant4_DIR=${BUILD_DIR_AUX} -DProject=cmsExp .. 
#      make -j1

  elif [ x"${APPLICATION_NAME}" = x"lArTestMT" ]; then
      env_sh=${GEANT4MT_BASE}/${APPLICATION_NAME}/setenv.sh

      # add cvmfs setup to setenv.sh
      #cat ${SRC_DIR}/g4p_setup_cvmfs.sh >> ${env_sh}
      cat ${SRC_DIR}/g4p_setup_gcc.sh >> ${env_sh}

      #CMake maual setup to link geant4 data: add locations of data to env file
      echo "#CMake manual setup to link geant4 data" >> ${env_sh} 
# --> consolidate apps -->      echo "export G4P_G4DIR=${GEANT4MT_BASE}/geant4mt.${GEANT4_RELEASE}" >> ${env_sh}
      echo "export G4P_G4DIR=${GEANT4MT_BASE}/geant4.${GEANT4_RELEASE}" >> ${env_sh}

      echo "...Building ${APPLICATION_NAME} ... with ${BUILDMT_DIR}"
      cmake -DGeant4_DIR=${BUILDMT_DIR} -DProject=lArTestMT .. 
      make -j1

      # if APPLICATION_NAME=lArTestMT, also need to build non-MT version of exe
      echo "...Building lArTest ... with ${BUILD_DIR_AUX}"
      cmake -DGeant4_DIR=${BUILD_DIR_AUX} -DProject=lArTest .. 
      make -j1
  else
    echo "... ${APPLICATION_NAME} is not valid ..."
    exit 1
  fi

  popd
  grep "path-to-data" ./g4p.init | \
    awk '{split($0,aa,"/"); print aa["1"]" "aa["2"]}' | \
    awk '{print "export "$3"=${G4P_G4DIR}/data/"$5}' >> ${env_sh}

  #add geant4 lib and application bin to LD_LIBRARY_PATH and PATH, respectively
  echo -e "\nexport LD_LIBRARY_PATH=\${G4P_G4DIR}/lib:\${LD_LIBRARY_PATH}" >> ${env_sh} 
  echo "export LD_LIBRARY_PATH=${COMPILER_DIR}/lib:\${LD_LIBRARY_PATH}" >> ${env_sh} 
  echo "export LD_LIBRARY_PATH=${COMPILER_DIR}/lib64:\${LD_LIBRARY_PATH}" >> ${env_sh} 
  echo "export LD_LIBRARY_PATH=${XERCESC_DIR}/lib:\${LD_LIBRARY_PATH}" >> ${env_sh} 

  #set the default gdml file and magnetic field map for cmsExp 
  if [ x"${APPLICATION_NAME}" = x"cmsExp" -o x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then
    echo "export G4P_APPLICATION_DIR=${APPLICATION_DIR}" >> ${env_sh}
    echo "export PATH=\${G4P_APPLICATION_DIR}/bin:\${PATH}" >> ${env_sh} 
    
    if [ x"${APPLICATION_NAME}" = x"cmsExp" ]; then
      echo "export CMSEXP_GDML=\${G4P_APPLICATION_DIR}/cmsExp.gdml" \
          >> ${env_sh} 
      echo "export CMSEXP_BFIELD_MAP=\${G4P_APPLICATION_DIR}/cmsExp.mag.3_8T" \
          >> ${env_sh} 
    fi

    if [ x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then
# now the migration...
#       cp $CFG_DIR/run_cmsExpMT.g4 ${APPLICATION_DIR}/run_cmsExpMT.g4
#       cp $CFG_DIR/template.oss_mt ${APPLICATION_DIR}/template.oss_cmsExpMT
#       sed "s%G4P_CMSEXPMT_DIR%${APPLICATION_DIR}%" \
#         $CFG_DIR/template.submit_mt_amd > ${APPLICATION_DIR}/submit_amd.sh
#       sed "s%G4P_CMSEXPMT_DIR%${APPLICATION_DIR}%" \
#         $CFG_DIR/template.submit_mt_intel > ${APPLICATION_DIR}/submit_intel.sh
#
      
       if [ x"$APPLICATION_RUN" = x ]; then
          APPLICATION_RUN=${SUBMIT_RUN_DIR}/build/g4mt.${GEANT4_RELEASE}/${APPLICATION_NAME}
       fi
       cp ${APPLICATION_DIR}/cmsExp.gdml ${APPLICATION_RUN}/cmsExp.gdml
       cp ${APPLICATION_DIR}/cmsExp.mag.3_8T ${APPLICATION_RUN}/cmsExp.mag.3_8T
       echo "export G4P_APPLICATION_RUN=${APPLICATION_RUN}" >> ${env_sh}
       echo "export CMSEXP_GDML=\${G4P_APPLICATION_RUN}/cmsExp.gdml" \
          >> ${env_sh} 
       echo "export CMSEXP_BFIELD_MAP=\${G4P_APPLICATION_RUN}/cmsExp.mag.3_8T" \
          >> ${env_sh} 
       
       cp $CFG_DIR/run_cmsExpMT.g4 ${APPLICATION_RUN}/run_cmsExpMT.g4
       # --> cp $CFG_DIR/template.oss_mt ${SUBMIT_RUN_DIR}/template.oss_cmsExpMT
       echo "... APPLICATION_RUN = ${APPLICATION_RUN} ..."
       # --> sed "s%./bin/cmsExpMT%${APPLICATION_DIR}/bin/cmsExpMT%" $CFG_DIR/template.oss_mt > ${APPLICATION_RUN}/template.oss_cmsExpMT
       # this is more generic as it'll replace both cmsExp and cmsExpMT
       sed "s%./bin/cmsExp%${APPLICATION_DIR}/bin/cmsExp%" $CFG_DIR/template.oss_mt > ${APPLICATION_RUN}/template.oss_cmsExpMT
# --> these resources no longer       sed "s%G4P_CMSEXPMT_DIR%${APPLICATION_RUN}%" \
#         $CFG_DIR/template.submit_mt_amd > ${APPLICATION_RUN}/submit_amd.sh
       #
       # NOTE(JVY): maybe make it input argument defined in g4p.init...
       #
       G4PMT_OUTPUT=/wclustre/g4p/g4p/pbs/mt_${GEANT4_RELEASE}_${APPLICATION_NAME} 
       echo " G4PMT_OUTPUT = ${G4PMT_OUTPUT} "      
       echo " CFG_DIR = ${CFG_DIR} "
       sed "s%G4P_CMSEXPMT_DIR%${APPLICATION_RUN}%" \
         ${CFG_DIR}/template.submit_mt_intel > ${APPLICATION_RUN}/submit_intel.sh
       sed -i "s%G4P_CMSEXPMT_OUT%${G4PMT_OUTPUT}%" ${APPLICATION_RUN}/submit_intel.sh
    fi      
  fi

  if [ x"${APPLICATION_NAME}" = x"lArTestMT" ]; then
    echo "export G4P_APPLICATION_DIR=${APPLICATION_DIR}" >> ${env_sh}
    echo "export PATH=\${G4P_APPLICATION_DIR}/bin:\${PATH}" >> ${env_sh} 
    cp $CFG_DIR/run_lArTestMT.g4 ${APPLICATION_DIR}/run_lArTestMT.g4
    cp $CFG_DIR/template.oss_lArTest_mt ${APPLICATION_DIR}/template.oss_lArTestMT
    sed "s%G4P_LARTESTMT_DIR%${APPLICATION_DIR}%" \
      $CFG_DIR/template.submit_lArTest_mt_amd > ${APPLICATION_DIR}/submit_amd.sh
    sed "s%G4P_LARTESTMT_DIR%${APPLICATION_DIR}%" \
      $CFG_DIR/template.submit_lArTest_mt_intel > ${APPLICATION_DIR}/submit_intel.sh
  fi

#  #set the default gdml file and magnetic field map for cmsExp 
#  if [ x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then
#    echo "export WORK_DIR=${APPLICATION_DIR}" \
#          >> ${env_sh} 
#    echo "export PATH=\${WORK_DIR}/bin:\${PATH}" \
#          >> ${env_sh} 
#    echo "export CMSEXP_GDML=\$WORK_DIR}/cmsExp.gdml" \
#          >> ${env_sh} 
#    echo "export CMSEXP_BFIELD_MAP=\${WORK_DIR}/cmsExp.mag.3_8T" \
#          >> ${env_sh} 
#    echo "export PATH=\${PATH}:/opt/OSS-2.0.2/bin" \
#          >> ${env_sh} 
#    echo "export OPENSS_RAWDATA_DIR=\${WORK_DIR}/raw" \
#          >> ${env_sh} 
#    echo "export OPENSS_DB_DIR=\${WORK_DIR}/db" \
#          >> ${env_sh} 
#
#    cp  ${env_sh} ${APPLICATION_DIR}/setenv_e-.sh
#    sed -i "s%raw%raw_e%" ${APPLICATION_DIR}/setenv_e-.sh
#    sed -i "s%db%rdb_e%"  ${APPLICATION_DIR}/setenv_e-.sh
#
#    for partid in "e- pi-" ; do
#      sed "s%G4P_APPLICATION_DIR%${APPLICATION_DIR}%" \
#          ${APPLICATION_DIR}/run_cmsExpMT_NoOSS.sh \
#          > ${APPLICATION_DIR}/run_cmsExpMT_${partid}_NoOSS.sh
#      sed -i "s%G4P_BEAM_PARTICLE%${partid}%" \
#      ${APPLICATION_DIR}/run_cmsExpMT_${partid}_NoOSS.sh
#    done
#    sed -i "s%G4P_APPLICATION_DIR%${APPLICATION_DIR}%" \
#    ${APPLICATION_DIR}/submit_mt 
#  fi

fi

pushd ${APPLICATION_DIR}
echo Changing permissions under ${APPLICATION_DIR}
chmod -R g+rw ${APPLICATION_DIR}

# also change permissions under SUBMIT_RUN_DIR, if necessary
if [ x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then
   echo Changing permissions under ${APPLICATION_RUN}
   chmod -R g+rw ${APPLICATION_RUN}
fi
