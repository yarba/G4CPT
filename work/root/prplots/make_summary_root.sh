#!/bin/bash

#
# Oct.2021 migration to WC-IC
#
source /cvmfs/larsoft.opensciencegrid.org/products/setup
setup root v6_18_04d -q e19:prof

file_list=`echo cpu_time_mean cpu_time_ratio`

sprof_dir="/work1/g4p/g4p/G4CPT/work/root/prplots"
for xfile in ${file_list} ; do
  echo "... make plots by $xfile ..."
  root.exe -q -b ${sprof_dir}/make_plots.C\(\"${xfile}\"\)
done
