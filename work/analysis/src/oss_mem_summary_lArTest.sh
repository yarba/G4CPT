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

#G4P_WEB_DIR=/g4/g4p/work
G4P_WEB_DIR=/home/g4p/webpages/g4p
G4P_CGI_DIR=/home/g4p/cgi-bin/data
G4P_EXP_DIR=${G4P_WEB_DIR}/oss_${GEANT4_VERSION}_${APPLICATION_NAME}_${EXP_NUM}
G4P_SQL_DIR=${G4P_CGI_DIR}/oss_${GEANT4_VERSION}_${APPLICATION_NAME}_${EXP_NUM}
G4P_ROOT_DIR=/g4/g4p/work/root/igprof
MEM_TEMPLATE=/g4/g4p/work/analysis/src/template_mem_summary_lArTest.html

#------------------------------------------------------------------------------
# sample list: 18 single particle samples
#------------------------------------------------------------------------------

sample_list="
 e-.FTFP_BERT.1.0
 e-.FTFP_BERT.5.0
 mu-.FTFP_BERT.1.0
 mu-.FTFP_BERT.5.0
 optical+e-.FTFP_BERT.1.0
 optical+mu-.FTFP_BERT.1.0
 optical+pi-.FTFP_BERT.1.0
 optical+proton.FTFP_BERT.1.0
 pi-.FTFP_BERT.1.0
 pi-.FTFP_BERT.5.0
 proton.FTFP_BERT.1.0
 proton.FTFP_BERT.5.0
"

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
done