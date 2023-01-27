#!/bin/bash

if [ $# -ne 1 ]; then
  echo -e "\nUsage: make_summary_root.sh [intel]"
  echo -e "     ex: make_summary_root.sh intel"
  exit 1
fi

node=$1

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
taskinganal_dir=/work1/g4p/g4p/G4CPT/work/root/taskinganal

#
# TMP commented
#
file_list=`echo throughput cpu_cores scaling meminfo memeff`
part_list=`echo pi elec`
ener_list=`echo 5 50`

# --> Jan.2021 migration to WC-IC
#
sprof_dir="/work1/g4p/g4p/G4CPT/work/root/taskinganal/src/${node}"
echo " sprof_dir = ${sprof_dir} "


for file in ${file_list} ; do
  for part in ${part_list} ; do
    for ener in ${ener_list} ; do
      unset xfile
      xfile=${file}_cmsExpTasking_${part}_E${ener}
      echo "... make plots by $xfile ..."
      root.exe -q -b ${sprof_dir}/make_plots.C\(\"${xfile}\"\)
    done
  done
done
