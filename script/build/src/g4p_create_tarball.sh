#!/bin/bash 

# svn keywords:
# $Rev: 1 $: Revision of last commit
# $Author: syjun $: Author of last commit
# $Date: 2011-10-19 09:10:28 $: Date of last commit

#------------------------------------------------------------------------------
# create a tarball to run a pbs job
#------------------------------------------------------------------------------
if [ $# -lt 4 ]; then
  echo "Usage: g4p_build_tarball.sh  G4P_PROJECT_DIR G4P_BLUARC_DIR G4P_RAMDISK_DIR \
               G4P_GEANT4_RELEASE G4P_APPLICATION_NAME" 
  exit 1
fi

PROJECT_DIR=$1
TAR_DESTINATION=$2
TARGET_RAMDISK=$3
GEANT4_RELEASE=$4
APPLICATION_NAME=$5

g4prefix=g4
geant4prefix=geant4
app_exe_name=${APPLICATION_NAME}

if [[ ${APPLICATION_NAME} =~ "VG" ]]; then
g4prefix=g4vg
geant4prefix=geant4vg
app_exe_name=${APPLICATION_NAME%%VG*}
fi

GEANT4_BASE=${PROJECT_DIR}/build/${g4prefix}.${GEANT4_RELEASE}
GEANT4_LIB=${GEANT4_BASE}/${geant4prefix}.${GEANT4_RELEASE}/lib
APPLICATION_DIR=${GEANT4_BASE}/${APPLICATION_NAME}


#prepare a directory for the tarball
# check if destination directory exists; if not, create it
if [ ! -d ${TAR_DESTINATION}/build ]; then
   mkdir -p ${TAR_DESTINATION}/build && echo "... Creating, ${TAR_DESTINATION}/build ..."
fi
if [ ! -d ${TAR_DESTINATION}/build/${g4prefix}.${GEANT4_RELEASE} ]; then
   mkdir -p ${TAR_DESTINATION}/build/${g4prefix}.${GEANT4_RELEASE} && echo "... Creating, ${TAR_DESTINATION}/build/${g4prefix}.${GEANT4_RELEASE} ..."
fi
# ---> PBS_TARBALL=${GEANT4_BASE}/geant4.${GEANT4_RELEASE}.${APPLICATION_NAME}.tar.gz
PBS_TARBALL=${TAR_DESTINATION}/build/${g4prefix}.${GEANT4_RELEASE}/${geant4prefix}.${GEANT4_RELEASE}.${APPLICATION_NAME}.tar.gz
TMP_TARBALL=${PWD}/${geant4prefix}.${GEANT4_RELEASE}.${APPLICATION_NAME}.tar.gz
if [ -f ${PBS_TARBALL} ]; then 
  echo "... ${PBS_TARBALL} already exists! ..."
  echo "... Do you want to overwrite the tarball? ..."
  echo "... Answer [no|yes] ..."
  unset confirm; read confirm
  if [ x"$confirm" = x"yes" ]; then 
    echo "... Removing  ${PBS_TARBALL} and creating a new tarball ... "
    rm -f ${PBS_TARBALL}
  else
    echo "... Creating a new ${PBS_TARBALL} cancelled ... "
    exit 1
  fi  
fi
pushd ${PROJECT_DIR}/build
 
#modify setup.sh for the pbs worker
sed "s%\${G4P_G4DIR}/lib%${TARGET_RAMDISK}/${g4prefix}.${GEANT4_RELEASE}/${geant4prefix}.${GEANT4_RELEASE}/lib%" \
     ${APPLICATION_DIR}/setenv.sh > ${APPLICATION_DIR}/setenv_pbs.sh

# ---> if [ x"${APPLICATION_NAME}" = x"cmsExp" ]; then
if [[ ${APPLICATION_NAME} =~ "cmsExp" ]]; then
  sed -i "s%${APPLICATION_DIR}%${TARGET_RAMDISK}/${g4prefix}.${GEANT4_RELEASE}/${APPLICATION_NAME}%" \
       ${APPLICATION_DIR}/setenv_pbs.sh 
fi

# ---> if [ x"${APPLICATION_NAME}" = x"cmsExp" ]; then
if [[ ${APPLICATION_NAME} =~ "cmsExp" ]]; then
 tar --exclude=\.svn -czf ${TMP_TARBALL} \
 ${g4prefix}.${GEANT4_RELEASE}/${geant4prefix}.${GEANT4_RELEASE}/lib \
 ${g4prefix}.${GEANT4_RELEASE}/*/bin/${app_exe_name} \
 ${g4prefix}.${GEANT4_RELEASE}/*/setenv_pbs.sh \
 ${g4prefix}.${GEANT4_RELEASE}/*/*.gdml \
 ${g4prefix}.${GEANT4_RELEASE}/*/*.mag.3_8T
elif [ x"${APPLICATION_NAME}" = x"lArTest" ]; then
 tar --exclude=\.svn -czf ${TMP_TARBALL} \
 ${g4prefix}.${GEANT4_RELEASE}/${geant4prefix}.${GEANT4_RELEASE}/lib \
 ${g4prefix}.${GEANT4_RELEASE}/lArTest/bin/${APPLICATION_NAME} \
 ${g4prefix}.${GEANT4_RELEASE}/lArTest/setenv_pbs.sh \
 ${g4prefix}.${GEANT4_RELEASE}/lArTest/lArBox.gdml
else
 tar --exclude=\.svn -czf ${TMP_TARBALL} \
 ${g4prefix}.${GEANT4_RELEASE}/${geant4prefix}.${GEANT4_RELEASE}/lib \
 ${g4prefix}.${GEANT4_RELEASE}/*/bin/${app_exe_name} \
 ${g4prefix}.${GEANT4_RELEASE}/*/setenv_pbs.sh 
fi

mv ${TMP_TARBALL} ${PBS_TARBALL}

#g4.${GEANT4_RELEASE}/${APPLICATION_NAME}/bin/${APPLICATION_NAME} \
#g4.${GEANT4_RELEASE}/${APPLICATION_NAME}/setenv_pbs.sh 

popd
echo "... created ${PBS_TARBALL}"
