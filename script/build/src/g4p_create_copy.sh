#!/bin/bash

# svn keywords:
# $Rev: 1 $: Revision of last commit
# $Author: syjun $: Author of last commit
# $Date: 2011-10-28 09:10:28 $: Date of last commit

#------------------------------------------------------------------------------
# copy geant4 and application to work area and fix environment variables
#------------------------------------------------------------------------------
if [ $# -lt 4 ]; then
  echo -e "\nUsage: g4p_condor_copy.sh G4P_PROJECT_DIR G4P_BLUEARC_DIR
    G4P_GEANT4_RELEASE G4P_APPLICATION_NAME \
    [G4P_APPLICATION_RELEASE] [G4P_CLHEP_RELEASE]" 
  exit 1
fi

PROJECT_DIR=$1
BLUEARC_DIR=$2
GEANT4_RELEASE=$3
APPLICATION_NAME=$4
APPLICATION_RELEASE=$5
CLHEP_RELEASE=$6

#------------------------------------------------------------------------------
# Check whether the copy dir and the target dir available
#------------------------------------------------------------------------------

copied_dir=${PROJECT_DIR}/build/g4.${GEANT4_RELEASE}
target_dir=${BLUEARC_DIR}/g4.${GEANT4_RELEASE}

if [ x"${APPLICATION_NAME}" = x"cmssw" ]; then
  copied_dir=${copied_dir}_cmssw_${APPLICATION_RELEASE}
  target_dir=${target_dir}_cmssw_${APPLICATION_RELEASE}
fi

if [ ! -d ${copied_dir} ]; then
  echo "...The copy source dir, ${copied_dir} does not exist ...Aborting" 
  exit 1
fi 

if [ ! -d ${BLUEARC_DIR} ]; then
  echo "...The mother of target dir does not exist ...Aborting" 
  exit 1
fi 

if [ -d ${target_dir} ]; then
  echo -e "... The target dir already exists. Do you want to overwrite \
the directory?\n... ${target_dir}\n" 
  echo "Answer [no|yes]"
  unset confirm; read confirm
  if [ x"$confirm" = x"yes" ]; then 
    echo "... Removing the target dir before copying ... "
    time rm -rf  ${target_dir}
  else 
    echo "... Copying to Condor Cancelled ... "
    exit 1
  fi
fi

#------------------------------------------------------------------------------
# Copy geant4 and application to the target dir
#------------------------------------------------------------------------------

echo "...   From  ${copied_dir} ..."
echo "...   To    ${target_dir} ..."

time cp -r ${copied_dir} ${target_dir}

if [ $? -eq 0 ]; then
  echo "... ${copied_dir} is successfully copied to"
  echo "... ${target_dir} ..."
else
  echo "... Failed to copy ${copied_dir} ... Aborting ..."
  exit 1
fi

#------------------------------------------------------------------------------
# Remove the symbolic link to geant4 data and copy selected data files
#------------------------------------------------------------------------------
rm -r ${target_dir}/geant4.${GEANT4_RELEASE}/data
mkdir ${target_dir}/geant4.${GEANT4_RELEASE}/data
data_list=`grep "path-to-data" ./g4p.init |\
       awk '{split($0,dd,"/"); print dd["2"]}'`
for dfile in ${data_list} ; do
#  echo "... Copying $dfile ..." 
#  cp -r ${PROJECT_DIR}/download/g4data/${dfile} \
#     ${target_dir}/geant4.${GEANT4_RELEASE}/data
  if [ -d ${BLUEARC_DIR}/download/g4data/${dfile} ]; then
    echo "... Linking $dfile ..." 
    ln -s ${BLUEARC_DIR}/download/g4data/${dfile} \
       ${target_dir}/geant4.${GEANT4_RELEASE}/data/${dfile}
  else
    echo "Warning ${BLUEARC_DIR}/download/g4data/${dfile} does not exist!"
  fi
done

#------------------------------------------------------------------------------
# Specific fix for SimplifiedCalo : geant4 environment 
#------------------------------------------------------------------------------

if [ x"${APPLICATION_NAME}" = x"SimplifiedCalo" -o \
     x"${APPLICATION_NAME}" = x"cmsExp" -o \
     x"${APPLICATION_NAME}" = x"SimplifiedCaloMT" -o \
     x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then

  for apps in SimplifiedCalo cmsExp  SimplifiedCaloMT cmsExpMT ; do
    env_sh=${BLUEARC_DIR}/g4.${GEANT4_RELEASE}/${apps}/setenv.sh
    [ -f ${env_sh} ] && sed -i_org1 "s%${PROJECT_DIR}/build%${BLUEARC_DIR}%" ${env_sh}
  done

#  if [ -f ${BLUEARC_DIR}/g4.${GEANT4_RELEASE}/${APPLICATION_NAME}/setenv.sh ]


elif [ x"${APPLICATION_NAME}" = x"cmssw" ]; then

  #copy clhep

  CLHEP_TOP=${BLUEARC_DIR}/clhep
  CLHEP_DIR=${CLHEP_TOP}/${CLHEP_RELEASE}

  if [ ! -d ${CLHEP_TOP} ]; then
    echo "... Copying CLHEP to ${CLHEP_TOP} ..."
    cp -r ${PROJECT_DIR}/download/clhep ${BLUEARC_DIR}
  else 
    if [ ! -d ${CLHEP_DIR} ]; then    
      echo "... Copying CLHEP to ${CLHEP_DIR} ..."
      cp -r ${PROJECT_DIR}/download/clhep/${CLHEP_RELEASE} ${CLHEP_TOP}
    else 
      echo "... Found ${CLHEP_DIR} ... OK ..."
    fi
  fi

  if [ -z "${CMS_PATH}" ] ; then 
    source /uscmst1/prod/sw/cms/shrc prod
  fi

  # 1) change directory appropriately
  APPLICATION_DIR=${target_dir}/CMSSW_${APPLICATION_RELEASE}

  pushd ${APPLICATION_DIR}/src
  scramv1 b ProjectRename

  cmstooldir=${APPLICATION_DIR}/config/toolbox/${SCRAM_ARCH}/tools/selected
  g4core_xml=$cmstooldir/geant4core.xml
  g4data_xml=$cmstooldir/geant4data.xml

  sed -i_org1 "s%${PROJECT_DIR}/build%${BLUEARC_DIR}%" ${g4core_xml}
  sed -i_org1 "s%${PROJECT_DIR}/build%${BLUEARC_DIR}%" ${g4data_xml}

  clhep_xml=$cmstooldir/clhep.xml
  clhepheader_xml=$cmstooldir/clhepheader.xml

  cat $clhep_xml
  echo ${PROJECT_DIR}/download
  echo ${BLUEARC_DIR}

  sed -i_org1 "s%${PROJECT_DIR}/download%${BLUEARC_DIR}%" ${clhep_xml}
  sed -i_org1 "s%${PROJECT_DIR}/download%${BLUEARC_DIR}%" ${clhepheader_xml}

  # 2) update changes for geant4
  for cms_xml in geant4 geant4core geant4data clhep clhepheader
  do
    scramv1 setup ${cms_xml} && scramv1 build ToolUpdated_${cms_xml}
  done

  popd

else
  echo "... Nothing is Copied.  Check G4P_APPLICATION_NAME ..."
fi
