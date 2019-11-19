
xver=$1
xapp=$2
xexp=$3

#analysis on the wilson cluster 
PBS_DIR=/g4/g4p/pbs
SRC_DIR=/g4/g4p/work/analysis/src
WEB_DIR=/home/g4p/webpages/g4p

PROJ_NAME="g4p_${xver}_${xapp}_${xexp}"
ANAL_DIR=/g4/g4p/work/${PROJ_NAME}

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

sample_list=`ls ${PBS_DIR}/${PROJ_NAME}/sprof |grep -v higgs`

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
 nsingle=2000
 unset energy
 energy=`echo $sample | awk '{split($0,arr,"."); print arr["3"]}'`
 if [ $energy = 1 ]; then
    nsingle=`expr $nsingle \* 10`
 fi
 if [ $energy = 5 ]; then
    nsingle=`expr $nsingle \* 2`
 fi
 echo "... process $sample ..."
 ${SRC_DIR}/process_analysis.sh ${xver} ${xapp} ${xexp} ${sample} ${nsingle}
done

echo "... process  higgs.FTFP_BERT.1400.4 ..."
${SRC_DIR}/process_analysis.sh ${xver} ${xapp} ${xexp} higgs.FTFP_BERT.1400.4 ${nhiggs} 

#post process for web pages
sed "s/G4P_PROJECT_NAME/${PROJ_NAME}/" ${SRC_DIR}/template_igprof.html \
                                     > ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
sed -i "s/G4P_APPLICATION/${xapp}/"    ${WEB_DIR}/${PROJ_NAME}/index_igprof.html
sed -i "s/G4P_VERSION/${xver}/"        ${WEB_DIR}/${PROJ_NAME}/index_igprof.html

sed "s/G4P_APPLICATION/${xapp}/" ${SRC_DIR}/template_sprof.html \
                               > ${WEB_DIR}/${PROJ_NAME}/index_sprof.html
sed -i "s/G4P_VERSION/${xver}/"  ${WEB_DIR}/${PROJ_NAME}/index_sprof.html

echo "... making CPU summary ..."
${SRC_DIR}/get_cpu_summary.sh ${xver} ${xapp} ${xexp}

echo "... making Memory summary ..."
${SRC_DIR}/get_mem_summary.sh ${xver} ${xapp} ${xexp}

echo "Done"
