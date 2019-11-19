#!/bin/bash

if [ $# -ne 2 ]; then
  echo -e "\nUsage: make_data.sh GEANT4_VERSION [amd|intel]"
  echo -e "     ex: make_data.sh 10.4.r00 amd"
  exit 1
fi

release=$1
node=$2

unset nthreads ; unset nthreads0
if [ x"${node}" = x"amd" ]; then
#
# JVY, 9/6/19: tmp remove 32 threads
#  nthreads="1 2 4 8 16 24 32"
#  nthreads0="0 1 2 4 8 16 24 32"
  nthreads="1 2 4 8 16 24"
  nthreads0="0 1 2 4 8 16 24"
elif [ x"${node}" = x"intel" ]; then
  nthreads="1 2 4 6 8 10 12"
  nthreads0="0 1 2 4 6 8 10 12"
else
  echo "node = $NODE is not valid, should be [amd|intel]" ; exit 1
fi

# --> migrate -->  NO YET...
log_dir=/g4/g4p/build/g4mt.${release}/cmsExpMT
# --> do NOT migrate yet --> log_dir=/lfstev/g4p/g4p/build/g4mt.${release}/cmsExpMT

if [ ! -d ${log_dir} ]; then
  echo "...The dir, ${log_dir} doesn't exist ..."; exit 1
fi

for en in 5 50 ; do
  for nt in ${nthreads} ; do
    grep " TimeEvent> " ${log_dir}/${node}_pi-_E${en}_t${nt}.log |\
    awk '{print $6}' >& cpu_core_pi-_E${en}_t${nt}.dat
    grep " TimeEvent> " ${log_dir}/${node}_e-_E${en}_t${nt}.log |\
    awk '{print $6}' >& cpu_core_e-_E${en}_t${nt}.dat
  done
  grep "TimeEvent> " ${log_dir}/${node}_pi-_E${en}_t0.log |\
  awk '{print $4}' >& cpu_core_pi-_E${en}_t0.dat
  grep "TimeEvent> " ${log_dir}/${node}_e-_E${en}_t0.log |\
  awk '{print $4}' >& cpu_core_e-_E${en}_t0.dat
done

for en in 5 50 ; do
  for nt in ${nthreads} ; do
    grep "TimeReport> " ${log_dir}/${node}_pi-_E${en}_t${nt}.log |\
    grep "G4WT" |\
    awk '{print $8}' >& scaling_pi-_E${en}_t${nt}.dat
    grep "TimeReport> " ${log_dir}/${node}_e-_E${en}_t${nt}.log |\
    grep "G4WT" |\
    awk '{print $8}' >& scaling_e-_E${en}_t${nt}.dat
  done
  grep "TimeReport> " ${log_dir}/${node}_pi-_E${en}_t0.log |\
  grep -v "G4WT" |\
  awk '{print $6}' >& scaling_pi-_E${en}_t0.dat
  grep "TimeReport> " ${log_dir}/${node}_e-_E${en}_t0.log |\
  grep -v "G4WT" |\
  awk '{print $6}' >& scaling_e-_E${en}_t0.dat
done

for en in 5 50 ; do
  for nt in $nthreads0 ; do
    unset nline;
    unset nline_end;
    #pion
    nline=`less ${log_dir}/${node}_pi-_E${en}_t${nt}.log |awk '{print NR" "$0}' | \
      grep openss |tail -1 | awk '{print $1}'`
    nline_end=`expr $nline + 120`
      less ${log_dir}/${node}_pi-_E${en}_t${nt}.log |\
      awk '{if(NR > '${nline}' && NR < '${nline_end}') print $0}' >& \
      ${node}_pi-_E${en}_t${nt}.dat
    #elecron
    nline=`less ${log_dir}/${node}_e-_E${en}_t${nt}.log |awk '{print NR" "$0}' | \
      grep openss |tail -1 | awk '{print $1}'`
    nline_end=`expr $nline + 120`
    less ${log_dir}/${node}_e-_E${en}_t${nt}.log |\
      awk '{if(NR > '${nline}' && NR < '${nline_end}') print $0}' >& \
      ${node}_e-_E${en}_t${nt}.dat
  done
done

for part in pi- e- ; do
  for en in 5 50 ; do
    for nt in $nthreads0 ; do
      if [ $nt == 0 ]; then
        grep "MemoryEvt> " ${log_dir}/${node}_${part}_E${en}_t${nt}.log |\
        awk '{print $4" "$5" "$6}' >& meminfo_${part}_E${en}_t${nt}.dat
      else
        grep "MemoryEvt> " ${log_dir}/${node}_${part}_E${en}_t${nt}.log |\
        awk '{print $6" "$7" "$8}' >& meminfo_${part}_E${en}_t${nt}.dat
      fi
    done
  done
done
