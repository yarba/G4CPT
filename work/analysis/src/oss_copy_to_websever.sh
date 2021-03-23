#!/bin/sh 

#------------------------------------------------------------------------------
# copy results from cluck to oink
#------------------------------------------------------------------------------
if [ $# -ne 3 ]; then
  echo -e "\nUsage: copy_to_oink.sh GEANT4_VERSION APPLICATION_NAME EXP_NUM"
  echo -e "     ex: copy_to_oink.sh 9.6 SimplifiedCalo 01"
  exit 1
fi

GEANT4_VERSION=$1
APP_NAME=$2
EXP_NUM=$3

G4P_PROJECT=oss_${GEANT4_VERSION}_${APP_NAME}_${EXP_NUM}
#
# --> migrate G4P_CGI_DIR=/home/g4p/cgi-bin/data/${G4P_PROJECT}
# --> migrate G4P_WEB_DIR=/home/g4p/webpages/g4p/${G4P_PROJECT}
# --> migrate G4P_SPROF_DIR=/home/g4p/webpages/g4p/summary/sprof
# --> migrate G4P_IGPROF_DIR=/home/g4p/webpages/g4p/summary/igprof
#
# --> Jan.2021 migrate to WC-IC
#
G4P_CGI_DIR=/work1/g4p/g4p/cgi-bin/data/${G4P_PROJECT}
G4P_WEB_DIR=/work1/g4p/g4p/webpages/g4p/${G4P_PROJECT}
G4P_SPROF_DIR=/work1/g4p/g4p/webpages/g4p/summary/sprof
G4P_IGPROF_DIR=/work1/g4p/g4p/webpages/g4p/summary/igprof


#------------------------------------------------------------------------------
# check the igprof directory
#------------------------------------------------------------------------------
if [ ! -d ${G4P_WEB_DIR} ]; then
  echo "...The dir, ${G4P_WEB_DIR} doesn't exist ..."; exit 1
fi

#if [ ! -d ${G4P_CGI_DIR} ]; then
#  echo "...The dir, ${G4P_CGI_DIR} doesn't exist ..."; exit 1
#fi

#
# --> Jan.2021 migration to WC-IC but these areas stay the same !
#
OINK_CGI_DIR=/geant4-perf/cgi-bin/data
OINK_WEB_DIR=/geant4-perf/g4p
OINK_SPROF_DIR=/geant4-perf/g4p/summary/sprof
OINK_IGPROF_DIR=/geant4-perf/g4p/summary/igprof

#------------------------------------------------------------------------------
# check and create the target directory
#------------------------------------------------------------------------------
echo "... Do you want to copy results of ${G4P_PROJECT} to g4cpt.fnal.gov? ..."
echo "... Answer [no|yes] ..."
unset confirm; read confirm
if [ x"$confirm" = x"yes" ]; then 
    echo "... Copying profiling results to /web/sites/g4cpt.fnal.gov ... "
    echo " copy dir from ${G4P_CGI_DIR} to ${OINK_CGI_DIR} "
    cp -r ${G4P_CGI_DIR} ${OINK_CGI_DIR}
    echo " copy dir ${G4P_WEB_DIR} to ${OINK_WEB_DIR} "
    cp -r ${G4P_WEB_DIR} ${OINK_WEB_DIR}
    echo "... Hold on copying summary plots ... "
#    echo " copy all PNG from ${G4P_SPROF_DIR} to ${OINK_SPROF_DIR} "
#    cp ${G4P_SPROF_DIR}/*.png ${OINK_SPROF_DIR}
#    echo " copy all PNG from ${G4P_IGPROF_DIR} to ${OINK_IGPROF_DIR} "
#    cp ${G4P_IGPROF_DIR}/*.png ${OINK_IGPROF_DIR}
else
    echo "... Copying to /web/sites/g4cpt.fnal.gov is cancelled ... "
    exit 1
fi
