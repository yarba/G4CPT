#!/bin/bash

if [ $# -ne 2 ]; then
  echo -e "\nUsage: make_summary_tasking.sh [release] [option]"
  echo -e "     ex: make_summary_tasking.sh 10.7.r04 rmf_mt"
  exit 1
fi

release=$1
option=$2

source /cvmfs/larsoft.opensciencegrid.org/products/setup
setup root v6_18_04d -q e19:prof
#
rmfanal_dir=/work1/g4p/g4p/G4CPT/work/root/rmf_anal

umask 0002

echo "... processing ${option}/Intel"
intel_dir=${rmfanal_dir}/g4${option}.${release}-intel

if [ -d ${intel_dir} ] ; then
  echo "... ${rmfanal_dir}, ${intel_dir} already exists! ..."
  echo "... Do you want to overwrite the directory? ..."
  echo "... Answer [no|yes] ..."
  unset confirm; read confirm
  if [ x"$confirm" = x"yes" ]; then 
    echo "... Removing ${intel_dir} and creating a new ${option} ... "
    rm -rf ${intel_dir}
  else
    echo "... Creating a new ${option} at ${intel_dir} cancelled ... "
    exit 1
  fi  
fi

mkdir -p ${intel_dir} 
cd ${intel_dir}
${rmfanal_dir}/src/make_data.sh ${release} intel ${option}
# --> ${taskinganal_dir}/src/make_summary_root.sh intel >& intel.log
echo "... Intel output at ${intel_dir}"
echo "... Done"
