#!/bin/bash

#source /products/setup
#setup root v5_34_01 -f Linux64bit+2.6-2.12 -q e2:prof
# source /home/g4p/products/root.v5.34.26/bin/thisroot.sh
#
# --> Jan.2021 migration to WC-IC
#
source /cvmfs/larsoft.opensciencegrid.org/products/setup
setup root v6_18_04d -q e19:prof
#
file_list=`echo cpu_time_mean cpu_time_ratio mem_count_total mem_count_ratio`

# --> migrate -->   sprof_dir="/g4/g4p/work/root"
# --> migrate again --> sprof_dir="/lfstev/g4p/g4p/work/root"
#
# Jan.2021 migration to WC-IC
#
sprof_dir="/work1/g4p/g4p/G4CPT/work/root"
for xfile in ${file_list} ; do
  echo "... make plots by $xfile ..."
  root.exe -q -b ${sprof_dir}/make_plots.C\(\"${xfile}\"\)
done
