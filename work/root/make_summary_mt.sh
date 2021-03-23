#!/bin/bash

if [ $# -ne 1 ]; then
  echo -e "\nUsage: make_summary_mt.sh [release]"
  echo -e "     ex: make_summary_mt.sh 10.4.r00"
  exit 1
fi

release=$1

#source /products/setup
#setup root v5_34_01 -f Linux64bit+2.6-2.12 -q e2:prof
# --> source /home/g4p/products/root.v5.34.26/bin/thisroot.sh
#
# --> migrate --> mtanal_dir=/g4/g4p/work/root/mtanal
# --> migrate again --> mtanal_dir=/lfstev/g4p/g4p/work/root/mtanal
#
# --> Jan.2021 migration to WC-IC
#
# NOTE(JVY): unfortunately, this build of root is NOT operational
#            as it misses libxxhash.so.0;
#            this is the case on both WC-IC (via /cvmfs/geant4-ib)
#            or LQ1 (via /cvmfs/larsoft)
#
#source /cvmfs/geant4-ib.opensciencegrid.org/products/setup
#setup root v6_20_08a -q e20:p383b:prof
#
source /cvmfs/larsoft.opensciencegrid.org/products/setup
setup root v6_18_04d -q e19:prof
#
mtanal_dir=/work1/g4p/g4p/G4CPT/work/root/mtanal

umask 0002

#
# --> Jan.2021 migration to WC-IC
#     NO such hardware anymore
#
#echo "... processing AMD"
#
#amd_dir=${mtanal_dir}/g4mt.${release}
#if [ -d ${amd_dir} ] ; then
#  echo "... mtanal, ${amd_dir} already exists! ..."
#  echo "... Do you want to overwrite the directory? ..."
#  echo "... Answer [no|yes] ..."
#  unset confirm; read confirm
#  if [ x"$confirm" = x"yes" ]; then 
#    echo "... Removing ${amd_dir} and creating a new mtanal ... "
#    rm -rf ${amd_dir}
#  else
#    echo "... Creating a new mtanal at ${amd_dir} cancelled ... "
#    exit 1
#  fi  
#fi
#
#mkdir -p ${amd_dir} 
#cd ${amd_dir}
#${mtanal_dir}/src/make_data.sh ${release} amd
#${mtanal_dir}/src/make_summary_root.sh amd >& amd.log
#echo "... AMD mtanal output at ${amd_dir}"

echo "... processing Intel"
intel_dir=${mtanal_dir}/g4mt.${release}-intel

if [ -d ${intel_dir} ] ; then
  echo "... mtanal, ${intel_dir} already exists! ..."
  echo "... Do you want to overwrite the directory? ..."
  echo "... Answer [no|yes] ..."
  unset confirm; read confirm
  if [ x"$confirm" = x"yes" ]; then 
    echo "... Removing ${intel_dir} and creating a new mtanal ... "
    rm -rf ${intel_dir}
  else
    echo "... Creating a new mtanal at ${intel_dir} cancelled ... "
    exit 1
  fi  
fi

mkdir -p ${intel_dir} 
cd ${intel_dir}
${mtanal_dir}/src/make_data.sh ${release} intel
${mtanal_dir}/src/make_summary_root.sh intel >& intel.log
echo "... Intel output at ${intel_dir}"
echo "... Done"
