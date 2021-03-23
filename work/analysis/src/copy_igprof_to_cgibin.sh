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
APP_NAME=$2
EXP_NUM=$3

#------------------------------------------------------------------------------
# setup sqlite
#------------------------------------------------------------------------------
#source /products/setup
#setup sqlite v3_07_17_00 -q prof

# --> migrate --> G4P_PBS_DIR=/g4/g4p/pbs
# --> migrate again --> G4P_PBS_DIR=/lfstev/g4p/g4p/pbs
# --> migrate again --> G4P_CGI_DIR=/home/g4p/cgi-bin/data
#
# Jan.2021 migration to WC-IC
#
G4P_PBS_DIR=/wclustre/g4p/g4p/pbs
G4P_CGI_DIR=/work1/g4p/g4p/cgi-bin/data

G4P_EXP_DIR=${G4P_PBS_DIR}/oss_${GEANT4_VERSION}_${APP_NAME}_${EXP_NUM}/igprof
G4P_SQL_DIR=${G4P_CGI_DIR}/oss_${GEANT4_VERSION}_${APP_NAME}_${EXP_NUM}

#------------------------------------------------------------------------------
# check the igprof directory
#------------------------------------------------------------------------------
if [ ! -d ${G4P_EXP_DIR} ]; then
  echo "...The dir, ${G4P_EXP_DIR} doesn't exist ..."; exit 1
fi

#------------------------------------------------------------------------------
# check and create the target directory
#------------------------------------------------------------------------------
if [ -d ${G4P_SQL_DIR} ] ; then
  echo "... Target Directory, ${G4P_SQL_DIR} already exists! ..."
  echo "... Do you want to overwrite the directory? ..."
  echo "... Answer [no|yes] ..."
  unset confirm; read confirm
  if [ x"$confirm" = x"yes" ]; then 
    echo "... Removing the application and creating a new one ... "
    rm -rf ${G4P_SQL_DIR}
  else
    echo "... Creating a new SQLite is cancelled ... "
    exit 1
  fi
fi

mkdir -p ${G4P_SQL_DIR}

#------------------------------------------------------------------------------
# sample list: 1 PYTHIA sample + 36 single particle samples
#------------------------------------------------------------------------------

unset sample_list

if [ x"${APP_NAME}" = x"lArTest" ]; then
  sample_list=`ls -l ${G4P_EXP_DIR} |grep drw |awk '{print $9}'`
else
  sample_list="higgs.FTFP_BERT.1400.4
   higgs.FTFP_BERT.1400.0
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
   pi-.FTFP_INCLXX.1.4
   pi-.FTFP_INCLXX.5.4
   pi-.FTFP_INCLXX.10.4
   pi-.FTFP_INCLXX.15.4
   anti_proton.FTFP_BERT.1.4
   anti_proton.FTFP_BERT.5.4
   anti_proton.FTFP_BERT.10.4
   anti_proton.FTFP_BERT.50.4
   proton.FTFP_BERT.1.4
   proton.FTFP_BERT.5.4
   proton.FTFP_BERT.10.4
   proton.FTFP_BERT.50.4
   proton.FTFP_INCLXX.1.4
   proton.FTFP_INCLXX.5.4
   proton.FTFP_INCLXX.10.4
   proton.FTFP_INCLXX.15.4
   proton.FTFP_BERT_HP.1.4
   proton.FTFP_BERT_HP.5.4
   proton.Shielding.1.4
   proton.Shielding.5.4
   e-100MeV.FTFP_BERT.100MeV.4
   e-100MeV.Shielding.100MeV.4
   e-100MeV.Shielding_EMZ.100MeV.4
   gamma.FTFP_BERT_EMZ_AugerOff.250MeV.0
   gamma.FTFP_BERT_EMZ_AugerOn.250MeV.0
   gamma.FTFP_BERT_EMZ_AugerOff.1.0
   gamma.FTFP_BERT_EMZ_AugerOn.1.0
"
fi

# defunct
# pi-.LHEP.1.4
# pi-.LHEP.5.4
# pi-.LHEP.10.4
# pi-.LHEP.50.4
#------------------------------------------------------------------------------
# copy files
#------------------------------------------------------------------------------

for sample in ${sample_list} ; do
  echo " ... Copying .. ${G4P_EXP_DIR}/${sample} ..."
  mkdir -p ${G4P_SQL_DIR}/${sample}
  cp -p ${G4P_EXP_DIR}/${sample}/*sql3 ${G4P_SQL_DIR}/${sample}
  cp -p ${G4P_EXP_DIR}/${sample}/*.log ${G4P_SQL_DIR}/${sample}
done
