#!/bin/sh 

xver1=$1
xver2=$2
xapp=$3

# --> migrate --> CPU_SUMMARY_1=/g4/g4p/work/root/sprof/cpu_summary_${xver1}_${xapp}.data
# --> migrate --> CPU_SUMMARY_2=/g4/g4p/work/root/sprof/cpu_summary_${xver2}_${xapp}.data
CPU_SUMMARY_1=/lfstev/g4p/g4p/work/root/sprof/cpu_summary_${xver1}_${xapp}.data
CPU_SUMMARY_2=/lfstev/g4p/g4p/work/root/sprof/cpu_summary_${xver2}_${xapp}.data

# --> migrate --> OUT_DIR=/g4/g4p/work/root/sprof
OUT_DIR=/lfstev/g4p/g4p/work/root/sprof
OUT_FILE=${OUT_DIR}/compare_${xver1}_vs_${xver2}.tex
# ---> OUT_FILE=test_compare.tex

while read -r line; do
CPU=`echo ${line} | awk '{print $1}'`
ERR=`echo ${line} | awk '{print $2}'`
SAMPLE=`echo ${line} | awk '{print $3}'`
printf "  %8.4f %8.4f \n" "${CPU}" "${ERR}"  >> tmp1.tex
printf " ${SAMPLE} \n" >> tmp_sample.tex
done < ${CPU_SUMMARY_1}

while read -r line; do
CPU=`echo ${line} | awk '{print $1}'`
ERR=`echo ${line} | awk '{print $2}'`
printf "  %8.4f %8.4f \n" "${CPU}" "${ERR}"  >> tmp2.tex
done < ${CPU_SUMMARY_2}

/usr/bin/paste tmp1.tex tmp2.tex >& tmp3.tex

/bin/rm -rf tmp1.tex
/bin/rm -rf tmp2.tex

less tmp3.tex | grep -v "#" | awk '{printf("%6.1f %4.1f\n",100.*($3-$1)/$1,100*($3/$1)*sqrt(($2/$1)*($2/$1)+($4/$3)*($4/$3)))}' >& tmp4.tex 

/usr/bin/paste tmp3.tex tmp4.tex >& tmp5.tex

/bin/rm -rf tmp3.tex
/bin/rm -rf tmp4.tex

/usr/bin/paste tmp5.tex tmp_sample.tex >& ${OUT_FILE} 

/bin/rm -rf tmp5.tex
/bin/rm -rf tmp_sample.tex


