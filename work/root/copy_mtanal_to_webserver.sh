#!/bin/bash

if [ $# -ne 1 ]; then
  echo -e "\nUsage: make_summary_mt.sh [release]"
  echo -e "     ex: make_summary_mt.sh 10.4.r00"
  exit 1
fi

release=$1

# --> migrate --> mtanal_dir=/g4/g4p/work/root/mtanal
# --> migrate again --> mtanal_dir=/lfstev/g4p/g4p/work/root/mtanal
#
# --> Jan.2021 migration to WC-IC
#
mtanal_dir=/work1/g4p/g4p/G4CPT/work/root/mtanal
html_src=${mtanal_dir}/src
web_dir=/geant4-perf/g4p/summary_mt/g4pmt_${release}_cmsExpMT

umask 0002

if [ -d ${web_dir} ] ; then
  echo "... mtanal, ${web_dir} already exists! ..."
  echo "... Do you want to overwrite the directory? ..."
  echo "... Answer [no|yes] ..."
  unset confirm; read confirm
  if [ x"$confirm" = x"yes" ]; then 
    echo "... Removing ${web_dir} and creating a new mtanal web ... "
    rm -rf ${web_dir}
  else
    echo "... Creating a new mtanal web at ${web_dir} cancelled ... "
    exit 1
  fi  
fi

mkdir -p ${web_dir} 
# --> migrate --> cp ${html_src}/*html ${web_dir} 
#
# --> Jn.2021 migration to WC-IC
#
cp ${html_src}/index_oss_wcic.html ${web_dir}
cp ${html_src}/summary_Intel.html ${web_dir}
sed -i "s/G4P_VERSION_CMSEXPMT/${release}/" ${web_dir}/*html

#
# --> Jan.2021 migration to WC-IC;
#     NO AMD resources anymore
#
#amd_dir=${mtanal_dir}/g4mt.${release}
#if [ -d ${amd_dir} ] ; then
#  echo "... copying from ${amd_dir} to ${web_dir}"
#  amd_plot_dir=${web_dir}/AMD
#  if [ ! -d ${amd_plot_dir} ]; then mkdir -p ${amd_plot_dir} ; fi
#  cp ${amd_dir}/amd_*.dat  ${web_dir}
#  cp ${amd_dir}/*png ${amd_plot_dir}
#else
#  echo "... ${amd_dir} does not exist ... bailing out"
#  exit 1
#fi  

intel_dir=${mtanal_dir}/g4mt.${release}-intel
if [ -d ${intel_dir} ] ; then
  echo "... copying from ${amd_dir} to ${web_dir}"
  intel_plot_dir=${web_dir}/Intel
  if [ ! -d ${intel_plot_dir} ]; then mkdir -p ${intel_plot_dir} ; fi
  cp ${intel_dir}/intel_*.dat  ${web_dir}
  cp ${intel_dir}/*png ${intel_plot_dir}
else
  echo "... ${intel_dir} does not exist ... bailing out"
  exit 1
fi  
