#!/bin/sh 

xver1=$1
xver2=$2
xapp=$3

# --> migrate --> MEM_SUMMARY_1=/g4/g4p/work/root/igprof/mem_summary_${xver1}_${xapp}.oss.END
# --> migrate --> MEM_SUMMARY_2=/g4/g4p/work/root/igprof/mem_summary_${xver2}_${xapp}.oss.END
MEM_SUMMARY_1=/lfstev/g4p/g4p/work/root/igprof/mem_summary_${xver1}_${xapp}.oss.END
MEM_SUMMARY_2=/lfstev/g4p/g4p/work/root/igprof/mem_summary_${xver2}_${xapp}.oss.END

# --> migrate --> OUT_DIR=/g4/g4p/work/root/igprof
OUT_DIR=/lfstev/g4p/g4p/work/root/igprof
OUT_FILE=${OUT_DIR}/compare_${xver1}_vs_${xver2}_${xapp}.tex
# ---> OUT_FILE=test_compare.tex

while read -r line; do
MEM=`echo ${line} | awk '{print $1}'`
SAMPLE=`echo ${line} | awk '{print $2}'`
printf "  %8.4f \n" "${MEM}"  >> tmp1.tex
printf " ${SAMPLE} \n" >> tmp_sample.tex
done < ${MEM_SUMMARY_1}

while read -r line; do
MEM=`echo ${line} | awk '{print $1}'`
printf "  %8.4f \n" "${MEM}"  >> tmp2.tex
done < ${MEM_SUMMARY_2}

/usr/bin/paste tmp1.tex tmp2.tex >& tmp3.tex

/bin/rm -rf tmp1.tex
/bin/rm -rf tmp2.tex

less tmp3.tex | grep -v "#" | awk '{printf("%4.1f\n",100.*($2-$1)/$1)}' >& tmp4.tex

/usr/bin/paste tmp3.tex tmp4.tex >& tmp5.tex

/bin/rm -rf tmp3.tex
/bin/rm -rf tmp4.tex

/usr/bin/paste tmp5.tex tmp_sample.tex >& ${OUT_FILE} 

/bin/rm -rf tmp5.tex
/bin/rm -rf tmp_sample.tex


