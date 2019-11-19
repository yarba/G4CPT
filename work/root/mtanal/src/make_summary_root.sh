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
source /home/g4p/products/root.v5.34.26/bin/thisroot.sh

file_list=`echo throughput cpu_cores scaling meminfo memeff`
part_list=`echo pi elec`
ener_list=`echo 5 50`

# --> migrate --> sprof_dir="/g4/g4p/work/root/mtanal/src/${node}"
sprof_dir="/lfstev/g4p/g4p/work/root/mtanal/src/${node}"
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
