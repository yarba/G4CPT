#!/bin/sh 

xver=$1
xapp=$2
xexp=$3

PBS_DIR=/lfstev/g4p/g4p/pbs/oss_${xver}_${xapp}_${xexp}/osspcsamp

CPU_SUMMARY=/g4/g4p/work/root/sprof/cpu_summary_${xver}_${xapp}.data

OUT_DIR=/lfstev/g4p/g4p/work/oss_${xver}_${xapp}_${xexp}
OUT_TABLE=${OUT_DIR}/cpu_total_${xver}_${xapp}.table

printf "\n  TOTAL CPU PER SAMPLE \n" >> ${OUT_TABLE}
printf "  RELEASE ${xver}, APPLICATION ${xapp} \n \n" >> ${OUT_TABLE}
printf "  CPU       ERR             SAMPLE \n \n" >> ${OUT_TABLE}

while read -r line; do
CPU=`echo ${line} | awk '{print $1}'`
ERR=`echo ${line} | awk '{print $2}'`
SAMPLE=`echo ${line} | awk '{print $3}'`
NEVT=`grep beamOn ${PBS_DIR}/${SAMPLE}/run_${xapp}.g4 | grep -v "#" | awk '{print $NF}'`
CPUTOTAL=`expr "$CPU * $NEVT" | bc`
ERRTOTAL=`expr "$ERR * $NEVT" | bc`
printf "  %6.1f %6.1f %s \n" "${CPUTOTAL}" "${ERRTOTAL}" "   ${SAMPLE}" >> ${OUT_TABLE}
done < ${CPU_SUMMARY}

