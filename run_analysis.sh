#!/usr/bin/env bash

cd /work1/g4p/g4p/G4CPT/work


echo " node `uname -n` "
echo " 1st arg is ${1} "
echo " 2nd arg is ${2} "
echo " 3rd arg is ${3} "

echo " Now in ${PWD} "

EXE=/work1/g4p/g4p/G4CPT/work/analysis/src/oss_process_all.sh

echo " Starting ${EXE} " 

${EXE} ${1} ${2} ${3} ${4} >& ana-${1}-${2}-${3}.log

