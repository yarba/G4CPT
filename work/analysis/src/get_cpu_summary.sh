#!/bin/sh 

#------------------------------------------------------------------------------
# make cpu summary html and data file
#------------------------------------------------------------------------------
if [ $# -ne 3 ]; then
  echo -e "\nUsage: get_cpu_summary.sh GEANT4_VERSION APPLICATION_NAME EXP_NUM"
  echo -e "     ex: get_cpu_summary.sh 10.1 SimplifiedCalo 01"
  exit 1
fi

GEANT4_VERSION=$1
APPLICATION_NAME=$2
EXP_NUM=$3

#G4P_WEB_DIR=/work/perfanalysis/webpages/g4p
#G4P_EXP_DIR=${G4P_WEB_DIR}/g4p_${GEANT4_VERSION}_${APPLICATION_NAME}_${EXP_NUM}
#CPU_TEMPLATE=/work/perfanalysis/g4p/analysis/src/template_cpu_summary.html
G4P_WEB_DIR=/home/g4p/webpages/g4p
G4P_EXP_DIR=${G4P_WEB_DIR}/g4p_${GEANT4_VERSION}_${APPLICATION_NAME}_${EXP_NUM}
G4P_ROOT_DIR=/g4/g4p/work/root/sprof
CPU_TEMPLATE=/g4/g4p/work/analysis/src/template_cpu_summary.html

#------------------------------------------------------------------------------
# sample list: 2 PYTHIA sample + 36 single particle samples
#------------------------------------------------------------------------------

sample_list="higgs.FTFP_BERT.1400.4
 e-.FTFP_BERT.1.0
 e-.FTFP_BERT.5.0
 e-.FTFP_BERT.10.0
 e-.FTFP_BERT.50.0
 e-.FTFP_BERT.1.4
 e-.FTFP_BERT.5.4
 e-.FTFP_BERT.10.4
 e-.FTFP_BERT.50.4
 pi-.FTFP_BERT.1.0
 pi-.FTFP_BERT.5.0
 pi-.FTFP_BERT.10.0
 pi-.FTFP_BERT.50.0
 pi-.FTFP_BERT.1.4
 pi-.FTFP_BERT.5.4
 pi-.FTFP_BERT.10.4
 pi-.FTFP_BERT.50.4
 pi-.QGSP_BERT.1.4
 pi-.QGSP_BERT.5.4
 pi-.QGSP_BERT.10.4
 pi-.QGSP_BERT.50.4
 pi-.QGSP_BIC.1.4
 pi-.QGSP_BIC.5.4
 pi-.QGSP_BIC.10.4
 pi-.QGSP_BIC.50.4
 anti_proton.FTFP_BERT.1.4
 anti_proton.FTFP_BERT.5.4
 anti_proton.FTFP_BERT.10.4
 anti_proton.FTFP_BERT.50.4
 proton.FTFP_BERT.1.4
 proton.FTFP_BERT.5.4
 proton.FTFP_BERT.10.4
 proton.FTFP_BERT.50.4
 pi-.FTFP_INCLXX.1.4
 pi-.FTFP_INCLXX.5.4
 pi-.FTFP_INCLXX.10.4
 pi-.FTFP_INCLXX.15.4
 proton.FTFP_INCLXX.1.4
 proton.FTFP_INCLXX.5.4
 proton.FTFP_INCLXX.10.4
 proton.FTFP_INCLXX.15.4
"

#------------------------------------------------------------------------------
# process list: IntelXeonCPU QuadCoreAMDOpteron
#------------------------------------------------------------------------------

#process_list="IntelXeonCPU QuadCoreAMDOpteron"
process_list="AMDOpteronProcessor6128"
#------------------------------------------------------------------------------
# check directory and get the summary data and html
#------------------------------------------------------------------------------
unset html_file
if [ ! -d ${G4P_EXP_DIR} ]; then
  echo "...The dir, ${G4P_EXP_DIR} doesn't exist ..."; exit 1
else
  html_file=${G4P_EXP_DIR}/cpu_summary.html
  [ -f ${html_file} ] && rm ${html_file}
fi

g4p_title=`echo ${GEANT4_VERSION} ${APPLICATION_NAME} ${EXP_NUM}`
sed "s%G4P_WEB_TITLE%${g4p_title}%" ${CPU_TEMPLATE} > ${html_file}

data_file="cpu_summary_${GEANT4_VERSION}_${APPLICATION_NAME}.data"
[ -e ${G4P_EXP_DIR}/${data_file} ] && rm ${G4P_EXP_DIR}/${data_file}
touch ${G4P_EXP_DIR}/${data_file}

for sample in ${sample_list} ; do
  for process in ${process_list}; do
    xfile="${G4P_EXP_DIR}/${sample}/prof_basic_trial_times_list.html"
    cpu_time=`grep $process ${xfile} |\
    awk '{split($0,aa,"</td><td>"); print aa["3"]}' |\
    awk '{split($0,bb,"</td>"); printf("%10.4f\n",bb["1"])}'`
    cpu_stdv=`grep $process ${xfile} |\
    awk '{split($0,aa,"</td><td>"); print aa["4"]}' |\
    awk '{split($0,bb,"</td>"); printf("%10.4f\n",bb["1"])}'`
    echo "$cpu_time $cpu_stdv   $sample"
    if [ ${cpu_time} ]; then
      echo "${cpu_time} ${cpu_stdv} $sample $process" >> ${G4P_EXP_DIR}/${data_file}
      sed -i "s%${sample}.${process}%${cpu_time}%" ${html_file}
    else 
      echo "    0.0 0.0  $sample $process" >> ${G4P_EXP_DIR}/${data_file}
      sed -i "s%${sample}.${process}%N/A%" ${html_file}
    fi
  done
  cp  ${G4P_EXP_DIR}/${data_file} ${G4P_ROOT_DIR}
done