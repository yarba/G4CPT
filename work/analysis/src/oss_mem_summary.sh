#!/bin/sh 

#------------------------------------------------------------------------------
# make cpu summary html and data file
#------------------------------------------------------------------------------
if [ $# -ne 3 ]; then
  echo -e "\nUsage: get_cpu_summary.sh GEANT4_VERSION APPLICATION_NAME EXP_NUM"
  echo -e "     ex: get_cpu_summary.sh 9.5 SimplifiedCalo 01"
  exit 1
fi

GEANT4_VERSION=$1
APPLICATION_NAME=$2
EXP_NUM=$3

#------------------------------------------------------------------------------
# setup sqlite
#------------------------------------------------------------------------------
#source /products/setup
#setup sqlite v3_07_08_00 -q gcc46:prof
#setup sqlite v3_07_17_00 -q prof

# --> migrate --> G4P_WORK_DIR=/g4/g4p/work
# --> migrate again --> G4P_WEB_DIR=/home/g4p/webpages/g4p/oss_${GEANT4_VERSION}_${APPLICATION_NAME}_${EXP_NUM}
# --> migrate again --> G4P_WORK_DIR=/lfstev/g4p/g4p/work
# --> migrate again --> G4P_CGI_DIR=/home/g4p/cgi-bin/data
#
#G4P_WEB_DIR=/work1/g4p/g4p/webpages/g4p/oss_${GEANT4_VERSION}_${APPLICATION_NAME}_${EXP_NUM}
#G4P_WORK_DIR=/work1/g4p/g4p/G4CPT/work
#G4P_CGI_DIR=/work1/g4p/g4p/cgi-bin/data
#
# G4P_EXP_DIR=${G4P_WORK_DIR}/oss_${GEANT4_VERSION}_${APPLICATION_NAME}_${EXP_NUM}
#G4P_SQL_DIR=${G4P_CGI_DIR}/oss_${GEANT4_VERSION}_${APPLICATION_NAME}_${EXP_NUM}
#
# --> migrate --> G4P_ROOT_DIR=/g4/g4p/work/root/igprof
# --> migrate again --> G4P_ROOT_DIR=/lfstev/g4p/g4p/work/root/igprof
#
# --> Jan.2021 migration to WC-IC
#
#
G4P_WEB_DIR=/work1/g4p/g4p/webpages/g4p/oss_${GEANT4_VERSION}_${APPLICATION_NAME}_${EXP_NUM}
G4P_EXP_DIR=${G4P_WEB_DIR}
#
G4P_CGI_DIR=/work1/g4p/g4p/cgi-bin/data
G4P_SQL_DIR=${G4P_CGI_DIR}/oss_${GEANT4_VERSION}_${APPLICATION_NAME}_${EXP_NUM}
#
G4P_SRC_DIR=/work1/g4p/g4p/G4CPT/work/analysis/src
G4P_ROOT_DIR=/work1/g4p/g4p/G4CPT/work/root/igprof


#
# --> migrate --> MEM_TEMPLATE=/g4/g4p/work/analysis/src/template_mem_summary.html
# --> MEM_TEMPLATE=${G4P_WORK_DIR}/analysis/src/template_mem_summary.html
MEM_TEMPLATE=${G4P_SRC_DIR}/template_mem_summary.html

#------------------------------------------------------------------------------
# sample list: 1 PYTHIA sample + 36 single particle samples
#------------------------------------------------------------------------------

sample_list="
 higgs.FTFP_BERT.1400.4
 higgs.FTFP_BERT.1400.0
 e-100MeV.FTFP_BERT.100MeV.4
 e-100MeV.Shielding.100MeV.4
 e-100MeV.Shielding_EMZ.100MeV.4
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
 proton.FTFP_BERT_HP.1.4
 proton.FTFP_BERT_HP.5.4
 proton.Shielding.1.4
 proton.Shielding.5.4
 gamma.FTFP_BERT_EMZ_AugerOff.250MeV.0
 gamma.FTFP_BERT_EMZ_AugerOn.250MeV.0
 gamma.FTFP_BERT_EMZ_AugerOff.1.0
 gamma.FTFP_BERT_EMZ_AugerOn.1.0
"

# ---> if [ x"${APPLICATION_NAME}" = x"cmsExp" ]; then
if [[ ${APPLICATION_NAME} =~ "cmsExp" ]]; then
sample_list="higgs.FTFP_BERT.1400.4"
# --> MEM_TEMPLATE=${G4P_WORK_DIR}/analysis/src/template_mem_summary_cmsExp.html
MEM_TEMPLATE=${G4P_SRC_DIR}/template_mem_summary_cmsExp.html
fi

#------------------------------------------------------------------------------
# process list: 
#------------------------------------------------------------------------------

process_list="MEM_TOTAL"
event_list="1 END"

#------------------------------------------------------------------------------
# check directory and get the summary data and html
#------------------------------------------------------------------------------
unset html_file
if [ ! -d ${G4P_EXP_DIR} ]; then
  echo "...The dir, ${G4P_EXP_DIR} doesn't exist ..."; exit 1
else
  html_file=${G4P_EXP_DIR}/mem_summary.html
  [ -f ${html_file} ] && rm ${html_file}
fi

g4p_title=`echo ${GEANT4_VERSION} ${APPLICATION_NAME} ${EXP_NUM}`
sed "s%G4P_WEB_TITLE%${g4p_title}%" ${MEM_TEMPLATE} > ${html_file}

for event_at in ${event_list}; do
  data_file="mem_summary_${GEANT4_VERSION}_${APPLICATION_NAME}.oss.${event_at}"
  [ -e ${G4P_EXP_DIR}/${data_file} ] && rm ${G4P_EXP_DIR}/${data_file}
  touch ${G4P_EXP_DIR}/${data_file}

  for sample in ${sample_list} ; do
    for process in ${process_list}; do
      unset total_count
      xfile="${G4P_SQL_DIR}/${sample}/IgProf_${sample}_${process}_${event_at}.sql3"
      total_count=`sqlite3 ${xfile} 'select total_count from summary' | awk '{print $1/1000000}'`
      if [ ${total_count} ]; then
        echo "${total_count} $sample $process ${event_at} " >> ${G4P_EXP_DIR}/${data_file}
        sed -i "s%${sample}.${process}.${event_at}%${total_count}%" ${html_file}
      else 
        echo "    0  $sample $process ${event_at} " >> ${G4P_EXP_DIR}/${data_file}
        sed -i "s%${sample}.${process}.${event_at}%N/A%" ${html_file}
      fi
    done
  done
  cp  ${G4P_EXP_DIR}/${data_file} ${G4P_ROOT_DIR}

  #copy files to the webpage
# -->  cp ${html_file} ${G4P_WEB_DIR}
# -->  cp ${G4P_EXP_DIR}/${data_file} ${G4P_WEB_DIR}
done

