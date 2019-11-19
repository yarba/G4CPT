#!/bin/bash

source /products/setup
setup root v5_34_01 -f Linux64bit+2.6-2.12 -q e2:prof

file_list=`echo cpu_time_mean_cmsExp cpu_time_ratio_cmsExp mem_count_total_cmsExp mem_count_ratio_cmsExp`

sprof_dir="/home/g4p/work/root"
for xfile in ${file_list} ; do
  echo "... make plots by $xfile ..."
  root.exe -q -b ${sprof_dir}/make_plots.C\(\"${xfile}\"\)
done
