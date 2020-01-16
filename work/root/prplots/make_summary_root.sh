#!/bin/bash

#source /products/setup
#setup root v5_34_01 -f Linux64bit+2.6-2.12 -q e2:prof
source /home/g4p/products/root.v5.34.26/bin/thisroot.sh
file_list=`echo cpu_time_mean cpu_time_ratio`

sprof_dir="/lfstev/g4p/g4p/work/root/prplots"
for xfile in ${file_list} ; do
  echo "... make plots by $xfile ..."
  root.exe -q -b ${sprof_dir}/make_plots.C\(\"${xfile}\"\)
done
