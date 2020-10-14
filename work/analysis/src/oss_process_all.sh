
xver=$1
xapp=$2
xexp=$3
nohwc=$4

#analysis on the wilson cluster 
#
# --> migrate --> PBS_DIR=/g4/g4p/pbs
# --> migrate --> SRC_DIR=/g4/g4p/work/analysis/src
#
PBS_DIR=/lfstev/g4p/g4p/pbs
SRC_DIR=/lfstev/g4p/g4p/work/analysis/src
#
WEB_DIR=/home/g4p/webpages/g4p

PROJ_NAME="oss_${xver}_${xapp}_${xexp}"
# --> migrate --> ANAL_DIR=/g4/g4p/work/${PROJ_NAME}
ANAL_DIR=/lfstev/g4p/g4p/work/${PROJ_NAME}

if [ -d ${ANAL_DIR} ]; then
  echo "... Analysis directory, ${ANAL_DIR} already exists! ..."
  echo "... Do you want to overwrite the directory? Answer [no|yes]"
  unset confirm; read confirm
  if [ x"$confirm" = x"yes" ]; then 
    echo "... Removing the analysis and creating a new one ... "
    rm -rf  ${PROJ_DIR}
  else 
    echo "... Creating a new analysis cancelled ..." ; exit 1
  fi
fi
mkdir ${ANAL_DIR}

sample_list=`ls ${PBS_DIR}/${PROJ_NAME}/osshwcsamp |grep -v higgs |grep -v "e\-100MeV" | grep -v all`

# --> if [ x"${xapp}" = x"cmsExp" ]; then
if [[ ${xapp} =~ "cmsExp" ]]; then
sample_list=""
fi

# PR plots (uncomment as needed)
#sample_list="higgs.FTFP_BERT.1400.4 
#e-.FTFP_BERT.1.4 
#e-.FTFP_BERT.50.4 
#pi-.FTFP_BERT.1.4 
#pi-.FTFP_BERT.50.4 
#anti_proton.FTFP_BERT.1.4
#anti_proton.FTFP_BERT.50.4
#proton.FTFP_BERT.1.4
#proton.FTFP_BERT.50.4
#"

# debugging scripts for year-summary plots
# sample_list="anti_proton.FTFP_BERT.1.4"
# sample_list="pi-.FTFP_BERT.50.4"

# 10.4.r09 extra processing !!!
# sample_list="pi-.QGSP_BERT.1.4 pi-.QGSP_BERT.50.4 pi-.QGSP_BIC.50.4 pi-.FTFP_INCLXX.1.4 proton.Shielding.1.4 proton.Shielding.5.4"

# TMP STUFF !!!
# --> sample_list="anti_proton.FTFP_BERT.10.4"
# --> alternative:  sample_list="e-.FTFP_BERT.10.4"

echo " sample_list = $sample_list"

unset nsingle;
unset nhiggs;
if [ x"${xapp}" = x"cmsExp" ]; then
#  nsingle=2000
  nhiggs=50
else
#  nsingle=2000
  nhiggs=50
fi

for sample in ${sample_list} ; do

 echo "Processing $sample "

 nsingle=2000
 unset energy
 energy=`echo $sample | awk '{split($0,arr,"."); print arr["3"]}'`
 if [ $energy = 1 ]; then
    nsingle=`expr $nsingle \* 10`
 fi
 if [ $energy = 5 ]; then
    nsingle=`expr $nsingle \* 2`
 fi

 if [ x"${xapp}" = x"lArTest" ]; then
   nsingle=1000
   if [ x"${sample:0:8}" = x"optical+" ]; then
     nsingle=26
   fi
 fi
 
 echo " energy = ${energy} "
 echo " nsingle = ${nsingle} "

 echo "... process $sample ..."
 ${SRC_DIR}/oss_analysis.sh ${xver} ${xapp} ${xexp} ${sample} ${nsingle} ${nohwc}
done


if [ x"${xapp}" = x"lArTest" ]; then
  echo "... processed lArTest samples ..."
  sed "s/G4P_PROJECT_NAME/${PROJ_NAME}/" ${SRC_DIR}/template_igprof_lArTest.html \
                                       > ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
  sed -i "s/G4P_APPLICATION/${xapp}/"    ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
  sed -i "s/G4P_VERSION/${xver}/"        ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
  
  sed "s/G4P_APPLICATION/${xapp}/" ${SRC_DIR}/template_sprof_lArTest.html \
                                 > ${WEB_DIR}/${PROJ_NAME}/index_sprof.html
  sed -i "s/G4P_VERSION/${xver}/"  ${WEB_DIR}/${PROJ_NAME}/index_sprof.html
  
  echo "... making CPU summary ..."
  ${SRC_DIR}/oss_cpu_summary_lArTest.sh ${xver} ${xapp} ${xexp}
  
  echo "... making Memory summary ..."
  ${SRC_DIR}/oss_mem_summary_lArTest.sh ${xver} ${xapp} ${xexp}
# --> elif [ x"${xapp}" = x"cmsExp" ]; then
elif [[ ${xapp} =~ "cmsExp" ]]; then

  echo "... process  higgs.FTFP_BERT.1400.4 ..."
  ${SRC_DIR}/oss_analysis.sh ${xver} ${xapp} ${xexp} higgs.FTFP_BERT.1400.4 ${nhiggs} ${nohwc}

  #post process for web pages
  sed "s/G4P_PROJECT_NAME/${PROJ_NAME}/" ${SRC_DIR}/template_igprof_cmsExp.html \
                                       > ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
  sed -i "s/G4P_APPLICATION/${xapp}/"    ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
  sed -i "s/G4P_VERSION/${xver}/"        ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
  
  sed "s/G4P_APPLICATION/${xapp}/" ${SRC_DIR}/template_sprof_cmsExp.html \
                                 > ${WEB_DIR}/${PROJ_NAME}/index_sprof.html
  sed -i "s/G4P_VERSION/${xver}/"  ${WEB_DIR}/${PROJ_NAME}/index_sprof.html
  
  echo "... making CPU summary ..."
  ${SRC_DIR}/oss_cpu_summary.sh ${xver} ${xapp} ${xexp}
  
  echo "... making Memory summary ..."
  ${SRC_DIR}/oss_mem_summary.sh ${xver} ${xapp} ${xexp}

else

  echo "... process  e-100MeV.FTFP_BERT.100MeV.4 ..."
  ${SRC_DIR}/oss_analysis.sh ${xver} ${xapp} ${xexp} e-100MeV.FTFP_BERT.100MeV.4 ${nhiggs} ${nohwc}

  echo "... process  e-100MeV.Shielding.100MeV.4 ..."
  ${SRC_DIR}/oss_analysis.sh ${xver} ${xapp} ${xexp} e-100MeV.Shielding.100MeV.4 ${nhiggs} ${nohwc}

  echo "... process  e-100MeV..Shielding_EMZ.100MeV.4 ..."
  ${SRC_DIR}/oss_analysis.sh ${xver} ${xapp} ${xexp} e-100MeV.Shielding_EMZ.100MeV.4 ${nhiggs} ${nohwc}

  echo "... process  higgs.FTFP_BERT.1400.4 ..."
  ${SRC_DIR}/oss_analysis.sh ${xver} ${xapp} ${xexp} higgs.FTFP_BERT.1400.4 ${nhiggs} ${nohwc}

  echo "... process  higgs.FTFP_BERT.1400.0 ..."
  ${SRC_DIR}/oss_analysis.sh ${xver} ${xapp} ${xexp} higgs.FTFP_BERT.1400.0 ${nhiggs} ${nohwc}

  #post process for web pages
  sed "s/G4P_PROJECT_NAME/${PROJ_NAME}/" ${SRC_DIR}/template_igprof.html \
                                       > ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
  sed -i "s/G4P_APPLICATION/${xapp}/"    ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
  sed -i "s/G4P_VERSION/${xver}/"        ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
  
  sed "s/G4P_APPLICATION/${xapp}/" ${SRC_DIR}/template_sprof.html \
                                 > ${WEB_DIR}/${PROJ_NAME}/index_sprof.html
  sed -i "s/G4P_VERSION/${xver}/"  ${WEB_DIR}/${PROJ_NAME}/index_sprof.html
  
  echo "... making CPU summary ..."
  ${SRC_DIR}/oss_cpu_summary.sh ${xver} ${xapp} ${xexp}
  
  echo "... making Memory summary ..."
  ${SRC_DIR}/oss_mem_summary.sh ${xver} ${xapp} ${xexp}
fi

# ---> echo "Archiving raw results for ${PROJ_NAME}"
# ---> ${SRC_DIR}/g4p_tar_and_copy_to_pnfs_archive.sh ${PROJ_NAME}

echo "Done"

