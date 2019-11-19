#!/bin/bash

# svn keywords:
# $Rev: 1 $: Revision of last commit
# $Author: syjun $: Author of last commit
# $Date: 2016-06-06 09:10:28 -0500 (Mon, 6 Jun 2016) $: Date of last commit

trap "echo 'Exiting due to user interrupt' && exit" INT

OUR_NODENAME=`uname -n`
echo This script is running on ${OUR_NODENAME}

echo " Number of input arguments $# "
if [ $# -lt 5 ]; then
  echo "Wrong number of arguments $#"
  echo "Must be at least 5 arguments"
  echo "GEANT release number (e.g. 10.2.p01) = $1"
  echo "Application (e.g. SimplifiedCalo or cmsExp) = $2"
  echo "Must supply experiment number e.g. 01 = $3"
  echo "Sample type (e.g. higgs.FTFP_BERT.1400.4 ) = $4"
  echo "Number of events per job (e.g. 50) =$5"
  echo "Optional 6th argument NoHwCSamp (case insensitive), to skip processing HW countins" 
  exit 1
fi

GEANT_RELEASE=$1
APPLICATION=$2
EXPERIMENT_NUMBER=$3
SAMPLE_NAME=$4
NEVENTS=$5
NOHWC=$6

# --> migrate --> BASE_DIR=/g4/g4p/work
# --> migrate --> PBS_DIR=/g4/g4p/pbs
BASE_DIR=/lfstev/g4p/g4p/work
PBS_DIR=/lfstev/g4p/g4p/pbs
#
WEB_DIR=/home/g4p/webpages/g4p
#
# --> migrate --> SRC_DIR=/g4/g4p/work/analysis/src
SRC_DIR=/lfstev/g4p/g4p/work/analysis/src


#-----------------------------------------------------------------------
# Move to the right directory to do all the work.
#-----------------------------------------------------------------------

PROJECT=oss_${GEANT_RELEASE}_${APPLICATION}_${EXPERIMENT_NUMBER}
PROJECT_DIR=${BASE_DIR}/${PROJECT}
SAMPLE_DIR=${PROJECT_DIR}/${SAMPLE_NAME}

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

thelist="osspcsamp  ossusertime"
if [ "x${NOHWC}" = "x" ]; then
thelist="osshwcsamp  osspcsamp  ossusertime"
fi
# for ossexp in osshwcsamp  osspcsamp  ossusertime ; do
# ---> for ossexp in osspcsamp  ossusertime ; do
for ossexp in ${thelist}; do
  TAR_DIR=${PBS_DIR}/${PROJECT}/${ossexp}/${SAMPLE_NAME}
  echo "... Counting tarballs in ${TAR_DIR} ..."
  TARBALL_NUMBER=`for ff in \`find ${TAR_DIR} -name g4profiling_\*.tgz -size +1c -print\`; do ls -la $ff; done | wc -l`
  RETURN_CODE=$?
  if (( ${RETURN_CODE} )) ;
  then
    echo "... Could not count tarballs ... Aborting."
    exit 1
  fi
  echo "... We have ${TARBALL_NUMBER} tarballs with the size greater than 0 bytes for ${ossexp} ..."

  if [ ${TARBALL_NUMBER} -lt 1 ]
  then
    echo "... No none-empty tarball to process ... Aborting ..."
    exit 1
  fi
done

#---------------------------------------------------------------------------------------------

tlist=`ls ${PBS_DIR}/${PROJECT}/oss*/${SAMPLE_NAME}/g4profiling_*tgz `

for tfile in $tlist ; do
  echo "... Processing $tfile ..."
  tar xzf ${tfile}
  idx=`echo ${tfile} |awk '{split($0,tid,"ling_"); print tid["2"]}' |\
                      awk '{split($0,sid,"."); print sid["1"]}'`

  TDTXT_NUMBER=`egrep "TimeReport> Time report complete in " trialdata_${idx}.txt | wc -l`

  #remove this line after tests
  sed -i "s%Memory \[VSIZE,RSS,SHR\] report complete in%Memory report complete in%" stdout_${idx}.txt

  if [ ${TDTXT_NUMBER} -ne 1 ]; then
     echo "... Unfinished Jobs: Removing g4profiling_${idx}.tgz ..."
     rm *_${idx}*
  else
    sed -i "s/G4WORKDIR/G4TOPDIR/" run_env_${idx}.txt
    echo "G4WORKDIR=/uscms_data/d2/${USER}/g4p/g4.${GEANT_RELEASE}/unmodified/work/SimplifiedCalo" >> run_env_${idx}.txt
      #we may concatenate all log files, but let's keep it last one for now
      cp stdout_${idx}.txt g4p_${SAMPLE_NAME}.log
  fi
done

#post oss data preparation to take advantage of with the current analysis 
namelist=`ls ${SAMPLE_DIR}/profdata_*_names`
for ff in $namelist ; do
  idx=`echo ${ff} |awk '{split($0,id,"data_"); print id["2"]}' | awk '{split($0,sid,"_name"); print sid["1"]}'`
  tail -n +8 ${ff} | awk '{split($3,fname,"\\(") ; print fname["1"]" "$1" "$2/100.}' | grep -v "cxx17" | \
       head -n 300 | awk '{if(NF==3) print $0}' > ossdata_${idx}_names 
done

liblist=`ls ${SAMPLE_DIR}/profdata_*_libraries`
for ff in $liblist ; do
  idx=`echo ${ff} |awk '{split($0,id,"data_"); print id["2"]}' | awk '{split($0,sid,"_lib"); print sid["1"]}'`
  tail -n +9 ${ff} | awk '{print $4" "$1" "$2" "$3/100.}' > ossdata_${idx}_libraries 
done

pathlist=`ls ${SAMPLE_DIR}/profdata_*_paths`
for ff in $pathlist ; do
  idx=`echo ${ff} |awk '{split($0,id,"data_"); print id["2"]}' | awk '{split($0,sid,"_path"); print sid["1"]}'`
  incl_time=`tail -n +8 ${ff} | head -1 |awk '{print $1}'`
  tail -n +8 ${ff} | awk -v scale=${incl_time} '{split($2,fname,"\\(") ; print fname["1"]" "$1" "$1/scale}' | grep -v "cxx17" | \
       head -n 300 | awk '{if(NF==3) print $0}' > ossdata_${idx}_paths 
done

hwclist=`ls ${SAMPLE_DIR}/profdata_*_hwcsamp`
for ff in $hwclist ; do
  idx=`echo ${ff} |awk '{split($0,id,"data_"); print id["2"]}' | awk '{split($0,sid,"_hwcsamp"); print sid["1"]}'`
  tail -n +8 ${ff} | awk '{split($9,fname,"\\(") ; if($6 ~ /^[0-9]*$/) print fname["1"]" "$2" "$3/$4" "$3" "$4" "$5" "$6}' | \
       grep -v "cxx17" | head -n 300 | awk '{if(NF==7) print $0}' > ossdata_${idx}_hwcsamp 
done
#some of hwcsamp output has a null field (empty) for fp_ops, so check that the last field is numberic
#---------------------------------------------------------------------------------------------


echo "... Now READY ${SAMPLE_DIR} ... "

echo "... Proceeding with the R scripts ..."

pushd ${BASE_DIR}

#pwd


${BASE_DIR}/analysis/src/oss_make_dataframes.rscript ${SAMPLE_DIR} ${NOHWC}
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Problems generating dataframes ... Aborting ..."
    exit 1
fi

#//--->this part is working. uncomment the section after testing
#if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
${BASE_DIR}/analysis/src/make_stepping_dataframe.rscript ${SAMPLE_DIR}
#fi
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Problems generating stepping dataframe ... Aborting ..."
    exit 1
fi

echo "SAMPLE_DIR = ${SAMPLE_DIR}"
echo "NEVENTS = ${NEVENTS}"
${BASE_DIR}/analysis/src/make_standard_plots_oss.rscript ${SAMPLE_DIR} ${NEVENTS} ${NOHWC}

RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Problems generating stepping plots ... Aborting ..."
    exit 1
fi
#if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
${BASE_DIR}/analysis/src/make_stepping_plots.rscript ${SAMPLE_DIR} ${NEVENTS}
#fi
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Problems generating stepping plots ... Aborting ..."
    exit 1
fi
#//<---this part is working. uncomment above section after testing

pwd

APPLHEAD=${APPLICATION:0:4}
echo ${APPLHEAD}

if [ ! -d ${WEB_DIR}/${PROJECT} ]; then
  echo "... Project ${WEB_DIR}/${PROJECT} doesn't exist. Creating ..."
  mkdir ${WEB_DIR}/${PROJECT}
fi

WEB_TAGET_DIR=${WEB_DIR}/${PROJECT}/${SAMPLE_NAME}
echo "Copying plots to the web pages area:"
echo "${WEB_TAGET_DIR}"

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
#        if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
  	  sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/SimplifiedCaloPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
#        else
#  	  sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/SimplifiedCaloPlots_bySample.html > ${WEB_TAGET_DIR}/index.html
#        fi
    else
	if mkdir ${WEB_TAGET_DIR}
	    then
	    cp ${TAR_DIR}/run_SimplifiedCalo.g4     ${WEB_TAGET_DIR}/run_SimplifiedCalo_${SAMPLE_NAME}.g4 
	    cp ${SAMPLE_DIR}/run_SimplifiedCalo_${SAMPLE_NAME}_g4.cfg ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/stdout_1_1.txt            ${WEB_TAGET_DIR}/run_SimplifiedCalo_${SAMPLE_NAME}.log 
	    cp ${SAMPLE_DIR}/prof_*.png ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.csv ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.html ${WEB_TAGET_DIR}
#            if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
	    sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/SimplifiedCaloPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
#            else
#	    sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/SimplifiedCaloPlots_bySample.html > ${WEB_TAGET_DIR}/index.html
#            fi
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
#        if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
  	  sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/cmsExpPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
#        else
#  	  sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/cmsExpPlots_bySample.html > ${WEB_TAGET_DIR}/index.html
#        fi
    else
	if mkdir ${WEB_TAGET_DIR}
	    then
	    cp ${TAR_DIR}/run_cmsExp.g4     ${WEB_TAGET_DIR}/run_cmsExp_${SAMPLE_NAME}.g4 
	    cp ${SAMPLE_DIR}/run_cmsExp_${SAMPLE_NAME}_g4.cfg ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/stdout_1_1.txt            ${WEB_TAGET_DIR}/run_cmsExp_${SAMPLE_NAME}.log 
	    cp ${SAMPLE_DIR}/prof_*.png ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.csv ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.html ${WEB_TAGET_DIR}
#            if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
    	      sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/cmsExpPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
#            else
#  	      sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/cmsExpPlots_bySample.html > ${WEB_TAGET_DIR}/index.html
#            fi
	else 
	    echo "Problems creating ${WEB_TAGET_DIR}"
	    echo "Aborting."
	    exit 1
	fi
    fi
fi

#-----------------------------------------------
# lArTest
#-----------------------------------------------
if [ ${APPLHEAD} = "lArT" ]
    then
    grep ^\/ ${TAR_DIR}/run_lArTest.g4 > ${SAMPLE_DIR}/run_lArTest_${SAMPLE_NAME}_g4.cfg
    if [ -d  ${WEB_TAGET_DIR} ]
	then
	cp ${TAR_DIR}/run_lArTest.g4     ${WEB_TAGET_DIR}/run_lArTest_${SAMPLE_NAME}.g4 
	cp ${SAMPLE_DIR}/run_lArTest_${SAMPLE_NAME}_g4.cfg ${WEB_TAGET_DIR}
        cp ${SAMPLE_DIR}/stdout_1_1.txt            ${WEB_TAGET_DIR}/run_lArTest_${SAMPLE_NAME}.log 
	cp ${SAMPLE_DIR}/prof_*.png ${WEB_TAGET_DIR}
	cp ${SAMPLE_DIR}/prof_*.csv ${WEB_TAGET_DIR}
	cp ${SAMPLE_DIR}/prof_*.html ${WEB_TAGET_DIR}
  	sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/lArTestPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
    else
	if mkdir ${WEB_TAGET_DIR}
	    then
	    cp ${TAR_DIR}/run_lArTest.g4     ${WEB_TAGET_DIR}/run_lArTest_${SAMPLE_NAME}.g4 
	    cp ${SAMPLE_DIR}/run_lArTest_${SAMPLE_NAME}_g4.cfg ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/stdout_1_1.txt            ${WEB_TAGET_DIR}/run_lArTest_${SAMPLE_NAME}.log 
	    cp ${SAMPLE_DIR}/prof_*.png ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.csv ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.html ${WEB_TAGET_DIR}
    	    sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/lArTestPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
	else 
	    echo "Problems creating ${WEB_TAGET_DIR}"
	    echo "Aborting."
	    exit 1
	fi
    fi
fi

##clean up
rm -f ${SAMPLE_DIR}/profdata_*_*
rm -f ${SAMPLE_DIR}/ossdata_*_*
rm -f ${SAMPLE_DIR}/*.openss
rm -f ${SAMPLE_DIR}/*.txt
rm -f ${SAMPLE_DIR}/*.rda

echo "All done"

exit
