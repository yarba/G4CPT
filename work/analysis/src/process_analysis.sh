#!/bin/bash

# svn keywords:
# $Rev: 714 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-03-24 15:10:28 -0500 (Thu, 24 Mar 2011) $: Date of last commit

# TODO: Move this to profiling-specific directory, preparing for move out of perfdb.

trap "echo 'Exiting due to user interrupt' && exit" INT

OUR_NODENAME=`uname -n`
echo This script is running on ${OUR_NODENAME}
#HOST_NODE="cluck.fnal.gov"
#
#if [ ${OUR_NODENAME} != ${HOST_NODE} ]
#then
#   echo This script expects to be run on ${HOST_NODE}
#   exit 1
#fi

if [ $# -ne 5 ]; then
  echo "Wrong number of arguments $#"
  echo "GEANT release number (e.g. 9.4.p01) = $1"
  echo "Application (e.g. SimplifiedCalo or cmssw426 or mu2e109) = $2"
  echo "Must supply experiment number e.g. 01 = $3"
  echo "Sample type (e.g. higgs e- pi- ) = $4"
  echo "Number of events per job (e.g. 100) =$5"
  exit 1
fi

GEANT_RELEASE=$1
APPLICATION=$2
EXPERIMENT_NUMBER=$3
SAMPLE_NAME=$4
NEVENTS=$5

BASE_DIR=/g4/g4p/work
PBS_DIR=/g4/g4p/pbs
WEB_DIR=/home/g4p/webpages/g4p
#-----------------------------------------------------------------------
# Move to the right directory to do all the work.
#-----------------------------------------------------------------------

PROJECT=g4p_${GEANT_RELEASE}_${APPLICATION}_${EXPERIMENT_NUMBER}
PROJECT_DIR=${BASE_DIR}/${PROJECT}
SAMPLE_DIR=${PROJECT_DIR}/${SAMPLE_NAME}
TAR_DIR=${PBS_DIR}/${PROJECT}/sprof/${SAMPLE_NAME}

if [ ! -d ${PROJECT_DIR} ]; then
  echo "... Project ${PROJECT_DIR} doesn't exist. Create one first"; exit 1
fi

mkdir $SAMPLE_DIR

if pushd ${SAMPLE_DIR}
then
   echo We are now in $PWD
else
   echo Failed to move to directory ${SAMPLE_DIR}
   exit 1
fi

# Adjust umask to that files are created with group read/write
umask 0002

#-----------------------------------------------------------------------
# Work starts here.
#-----------------------------------------------------------------------

echo "... Counting tarballs ..."
TARBALL_NUMBER=`for ff in \`find ${TAR_DIR} -name g4profiling_\*.tgz -size +1c -print\`; do ls -la $ff; done | wc -l`
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Could not count tarballs ... Aborting."
    exit 1
fi
echo "... We have ${TARBALL_NUMBER} tarballs with the size greater than 0 bytes ..."

if [ ${TARBALL_NUMBER} -lt 1 ]
then
    echo "... No none-empty tarball to process ... Aborting ..."
    exit 1
fi

#---------------------------------------------------------------------------------------------

tlist=`ls ${TAR_DIR}/g4profiling_*tgz`
for tfile in $tlist ; do
  echo "... Processing $tfile ..."
  tar xzf ${tfile}
  idx=`echo ${tfile} |awk '{split($0,tid,"ing_"); print tid["2"]}' |\
                      awk '{split($0,sid,"."); print sid["1"]}'`

  TDTXT_NUMBER=`egrep "TimeReport> Time report complete in " trialdata_${idx}.txt | wc -l`

  unset PD_NONEMPTY_NUMBER
  unset PD_COLUMNN_LIBRARIES

  if [ ${TDTXT_NUMBER} -ne 1 ]; then
     echo "... Unfinished Jobs: Removing g4profiling_${idx}.tgz ..."
     rm *_${idx}*
  else
    PD_NONEMPTY_NUMBER=`find . -name profdata_${idx}_names -size +1c -print | wc -l`
    PD_COLUMNN_LIBRARIES=`head -n 1 profdata_${idx}_libraries | wc -w`
    sed -i "s/G4WORKDIR/G4TOPDIR/" run_env_${idx}.txt
    echo "G4WORKDIR=/uscms_data/d2/${USER}/g4p/g4.${GEANT_RELEASE}/unmodified/work/SimplifiedCalo" >> run_env_${idx}.txt
    if [ ${PD_NONEMPTY_NUMBER} -ne 1 -o ${PD_COLUMNN_LIBRARIES} -ne 3 ]; then
      echo "... Bad Profiling: Skipping g4profiling_${idx}.tgz ..."
      rm *_${idx}*
    else
      #we may concatenate all log files, but let's keep it last one for now
      cp stdout_${idx}.txt g4p_${SAMPLE_NAME}.log
    fi
  fi

done
#---------------------------------------------------------------------------------------------
echo "... Proceeding with the R scripts ..."

pushd ${BASE_DIR}

pwd

${BASE_DIR}/analysis/src/make_dataframes.rscript ${SAMPLE_DIR}
if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
  ${BASE_DIR}/analysis/src/make_stepping_dataframe.rscript ${SAMPLE_DIR}
fi
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Problems generating dataframes ... Aborting ..."
    exit 1
fi

${BASE_DIR}/analysis/src/make_standard_plots_test.rscript ${SAMPLE_DIR} ${NEVENTS}
if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
  ${BASE_DIR}/analysis/src/make_stepping_plots.rscript ${SAMPLE_DIR} ${NEVENTS}
fi
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Problems generating plots ... Aborting ..."
    exit 1
fi

pwd

APPLHEAD=${APPLICATION:0:4}
echo ${APPLHEAD}

if [ ! -d ${WEB_DIR}/${PROJECT} ]; then
  echo "... Project ${WEB_DIR}/${PROJECT} doesn't exist. Creating ..."
  mkdir ${WEB_DIR}/${PROJECT}
fi

WEB_TAGET_DIR=${WEB_DIR}/${PROJECT}/${SAMPLE_NAME}
echo "Copying plots to the web pages area:"
echo "${WEB_TARGET_DIR}"

if [ ${APPLHEAD} = "Simp" ]
    then
    grep ^\/ ${TAR_DIR}/run_SimplifiedCalo.g4 > ${SAMPLE_DIR}/run_SimplifiedCalo_${SAMPLE_NAME}_g4.cfg
    if [ -d  ${WEB_TAGET_DIR} ]
	then
	cp ${TAR_DIR}/run_SimplifiedCalo.g4     ${WEB_TAGET_DIR}/run_SimplifiedCalo_${SAMPLE_NAME}.g4 
	cp ${SAMPLE_DIR}/run_SimplifiedCalo_${SAMPLE_NAME}_g4.cfg ${WEB_TAGET_DIR}
        cp ${SAMPLE_DIR}/stdout_1_1.txt            ${WEB_TAGET_DIR}/run_SimplifiedCalo_${SAMPLE_NAME}.log 
	cp ${SAMPLE_DIR}/prof_*.png ${WEB_TAGET_DIR}
	cp ${SAMPLE_DIR}/prof_*.csv ${WEB_TAGET_DIR}
	cp ${SAMPLE_DIR}/prof_*.html ${WEB_TAGET_DIR}
        if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
  	  sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/SimplifiedCaloPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
        else
  	  sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/SimplifiedCaloPlots_bySample.html > ${WEB_TAGET_DIR}/index.html
        fi
    else
	if mkdir ${WEB_TAGET_DIR}
	    then
	    cp ${TAR_DIR}/run_SimplifiedCalo.g4     ${WEB_TAGET_DIR}/run_SimplifiedCalo_${SAMPLE_NAME}.g4 
	    cp ${SAMPLE_DIR}/run_SimplifiedCalo_${SAMPLE_NAME}_g4.cfg ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/stdout_1_1.txt            ${WEB_TAGET_DIR}/run_SimplifiedCalo_${SAMPLE_NAME}.log 
	    cp ${SAMPLE_DIR}/prof_*.png ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.csv ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.html ${WEB_TAGET_DIR}
            if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
	    sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/SimplifiedCaloPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
            else
	    sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/SimplifiedCaloPlots_bySample.html > ${WEB_TAGET_DIR}/index.html
            fi
	else 
	    echo "Problems creating ${WEB_TAGET_DIR}"
	    echo "Aborting."
	    exit 1
	fi
    fi
fi
#-----------------------------------------------
# cmsExp
#-----------------------------------------------
if [ ${APPLHEAD} = "cmsE" ]
    then
    grep ^\/ ${TAR_DIR}/run_cmsExp.g4 > ${SAMPLE_DIR}/run_cmsExp_${SAMPLE_NAME}_g4.cfg
    if [ -d  ${WEB_TAGET_DIR} ]
	then
	cp ${TAR_DIR}/run_cmsExp.g4     ${WEB_TAGET_DIR}/run_cmsExp_${SAMPLE_NAME}.g4 
	cp ${SAMPLE_DIR}/run_cmsExp_${SAMPLE_NAME}_g4.cfg ${WEB_TAGET_DIR}
        cp ${SAMPLE_DIR}/stdout_1_1.txt            ${WEB_TAGET_DIR}/run_cmsExp_${SAMPLE_NAME}.log 
	cp ${SAMPLE_DIR}/prof_*.png ${WEB_TAGET_DIR}
	cp ${SAMPLE_DIR}/prof_*.csv ${WEB_TAGET_DIR}
	cp ${SAMPLE_DIR}/prof_*.html ${WEB_TAGET_DIR}
        if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
  	  sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/cmsExpPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
        else
  	  sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/cmsExpPlots_bySample.html > ${WEB_TAGET_DIR}/index.html
        fi
    else
	if mkdir ${WEB_TAGET_DIR}
	    then
	    cp ${TAR_DIR}/run_cmsExp.g4     ${WEB_TAGET_DIR}/run_cmsExp_${SAMPLE_NAME}.g4 
	    cp ${SAMPLE_DIR}/run_cmsExp_${SAMPLE_NAME}_g4.cfg ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/stdout_1_1.txt            ${WEB_TAGET_DIR}/run_cmsExp_${SAMPLE_NAME}.log 
	    cp ${SAMPLE_DIR}/prof_*.png ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.csv ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.html ${WEB_TAGET_DIR}
            if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
    	      sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/cmsExpPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
            else
  	      sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/cmsExpPlots_bySample.html > ${WEB_TAGET_DIR}/index.html
            fi
	else 
	    echo "Problems creating ${WEB_TAGET_DIR}"
	    echo "Aborting."
	    exit 1
	fi
    fi
fi

if [ ${APPLHEAD} = "cmss" ]
    then
    if [ -d ${WEB_TAGET_DIR} ]
	then
	cp ${SAMPLE_DIR}/run_sim_*_cfg.py     ${WEB_TAGET_DIR}
	cp ${PROJECT_DIR}/prof_*.png ${WEB_TAGET_DIR}
	cp ${PROJECT_DIR}/prof_*.html ${WEB_TAGET_DIR}
	cp ${BASE_DIR}/analysis/src/cmsswPlots.html ${WEB_TAGET_DIR}/index.html
    else
	if mkdir ${WEB_TAGET_DIR}
	    then
	    cp ${SAMPLE_DIR}/run_sim_*_cfg.py ${WEB_TAGET_DIR}
	    cp ${PROJECT_DIR}/prof_*.png ${WEB_TAGET_DIR}
	    cp ${PROJECT_DIR}/prof_*.html ${WEB_TAGET_DIR}
	    cp ${BASE_DIR}/analysis/src/cmsswPlots.html ${WEB_TAGET_DIR}/index.html
	else 
	    echo "Problems creating ${WEB_TAGET_DIR}"
	    echo "Aborting."
	    exit 1
	fi
    fi
    CFGAUX=g4.${GEANT_RELEASE}_${APPLICATION}
    sed -i~ "s/run_SimplifiedCalo.g4/run_sim_${CFGAUX//./}_cfg.py/g" ${WEB_TAGET_DIR}/index.html
fi
if [ ${APPLHEAD} = "mu2e" ]
    then
    if [ -d ${WEB_TAGET_DIR} ]
	then
	cp ${SAMPLE_DIR}/prof.fcl     ${WEB_TAGET_DIR}
	cp ${PROJECT_DIR}/prof_*.png ${WEB_TAGET_DIR}
	cp ${PROJECT_DIR}/prof_*.html ${WEB_TAGET_DIR}
	cp ${BASE_DIR}/analysis/src/mu2ePlots.html ${WEB_TAGET_DIR}/index.html
    else
	if mkdir ${WEB_TAGET_DIR}
	    then
	    cp ${SAMPLE_DIR}/prof.fcl ${WEB_TAGET_DIR}
	    cp ${PROJECT_DIR}/prof_*.png ${WEB_TAGET_DIR}
	    cp ${PROJECT_DIR}/prof_*.html ${WEB_TAGET_DIR}
	    cp ${BASE_DIR}/analysis/src/mu2ePlots.html ${WEB_TAGET_DIR}/index.html
	else 
	    echo "Problems creating ${WEB_TAGET_DIR}"
	    echo "Aborting."
	    exit 1
	fi
    fi
fi

#clean up
rm -f ${SAMPLE_DIR}/profdata_*_*
#rm -f ${SAMPLE_DIR}/*.txt

echo "All done"

exit
