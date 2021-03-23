#!/bin/bash

if [ $# -ne 1 ]; then
  echo -e "\nUsage: make_summary_root.sh [amd|intel]"
  echo -e "     ex: make_summary_root.sh amd"
  exit 1
fi

#version=$1
node=$1

#source /products/setup
#setup root v5_34_01 -f Linux64bit+2.6-2.12 -q e2:prof
# --> migrate --> source /home/g4p/products/root.v5.34.26/bin/thisroot.sh
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

#
# TMP commented
#
file_list=`echo throughput cpu_cores scaling meminfo memeff`
part_list=`echo pi elec`
ener_list=`echo 5 50`
#
# TESTING ONLY !!!
#
#file_list=`echo cpu_cores meminfo memeff`
#part_list=`echo pi elec`
#ener_list=`echo 50 5`

# --> migrate --> sprof_dir="/g4/g4p/work/root/mtanal/src/${node}"
# --> migrate again --> sprof_dir="/lfstev/g4p/g4p/work/root/mtanal/src/${node}"
#
# --> Jan.2021 migration to WC-IC
#
sprof_dir="/work1/g4p/g4p/G4CPT/work/root/mtanal/src/${node}"
echo " sprof_dir = ${sprof_dir} "


for file in ${file_list} ; do
  for part in ${part_list} ; do
    for ener in ${ener_list} ; do
      unset xfile
      xfile=${file}_cmsExpMT_${part}_E${ener}
      echo "... make plots by $xfile ..."
      root.exe -q -b ${sprof_dir}/make_plots.C\(\"${xfile}\"\)
    done
  done
done
