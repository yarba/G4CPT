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
# --> migrate again --> BASE_DIR=/lfstev/g4p/g4p/work
# --> migrate again --> PBS_DIR=/lfstev/g4p/g4p/pbs
#
# --> migrate --> WEB_DIR=/home/g4p/webpages/g4p
#
# --> migrate --> SRC_DIR=/g4/g4p/work/analysis/src
# --> migrate again --> SRC_DIR=/lfstev/g4p/g4p/work/analysis/src
#
# --> Jan.2021 migration to WC-IC
#
# --> disk space problems --> BASE_DIR=/work1/g4p/g4p/G4CPT/work
BASE_DIR=/tmp
PBS_DIR=/wclustre/g4p/g4p/pbs
#
WEB_DIR=/work1/g4p/g4p/webpages/g4p
#
export SRC_DIR=/work1/g4p/g4p/G4CPT/work/analysis/src

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
  TARBALL_NUMBER=`for ff in \`find ${TAR_DIR} -name g4profiling_\*.tgz -size +1c -print | grep -v resu \`; do ls -la $ff; done | wc -l`
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

# weed out corrupted ossusertime outputs
#
# *** tlist=`ls ${PBS_DIR}/${PROJECT}/ossusertime/${SAMPLE_NAME}/g4profiling_*tgz `
## tlist=`zgrep -ai "Error during termination" ${PBS_DIR}/${PROJECT}/ossusertime/${SAMPLE_NAME}/g4profiling_*tgz |\
##	awk -F ":" '{print $1}'`
## #for tf in ${tlist}; do
## #echo " ... Removing problematic ${tf} ... "
## #rm -f ${tf}
## #done

tlist=`zgrep -ai "No valid experiment" ${PBS_DIR}/${PROJECT}/oss*/${SAMPLE_NAME}/g4profiling_*tgz |\
	awk -F ":" '{print $1}'`

for tf in ${tlist}; do
## --> rm -rf ${tf}
mv ${tf} ${tf}-problematic
done

# now redefine tlist for further processing
#
tlist=`ls ${PBS_DIR}/${PROJECT}/oss*/${SAMPLE_NAME}/g4profiling_*tgz `

for tfile in $tlist ; do
  echo "... Processing $tfile ..."
  tar xzf ${tfile}
  
# (alternative way to) weed out problematic messages 
# from post-processing of ossusrtime outputs
#
problematic_list=`grep "Error during termination" * | awk -F ":" '{print $1}'`
for ptf in ${problematic_list} ; do
#     more ${ptf} | grep -v "Error during termination" > ${ptf}.save
#     mv ${ptf}.save ${ptf}
# --->   problematic_line=`grep "Error during" ${ptf} | awk -F ":" '{print $2}'`
   problematic_line=`grep "Error during" ${ptf}`
# --->   echo " problematic_line = ${problematic_line}"
   sed -i "s%${problematic_line}%%" ${ptf}
done
#problematic_list=`grep "catch_signal 11" * | awk -F ":" '{print $1}'`
#for ptf in ${problematic_list}; do
#     sed -i "s%catch_signal 11% %" ${ptf}
#done
  
  idx=`echo ${tfile} |awk '{split($0,tid,"ling_"); print tid["2"]}' |\
                      awk '{split($0,sid,"."); print sid["1"]}'`

# --->  TDTXT_NUMBER=`egrep "TimeReport> Time report complete in " trialdata_${idx}.txt | wc -l`
  TDTXT_NUMBER=`egrep "TimeReport> Time report complete in " trialdata_${idx}.txt | egrep -v G4WT | wc -l`

  #remove this line after tests
  sed -i "s%Memory \[VSIZE,RSS,SHR\] report complete in%Memory report complete in%" stdout_${idx}.txt

  if [ ${TDTXT_NUMBER} -ne 1 ]; then
     echo "... Unfinished Jobs: Removing g4profiling_${idx}.tgz ..."
     rm *_${idx}*
  else
    sed -i "s/G4WORKDIR/G4TOPDIR/" run_env_${idx}.txt
    # --> echo "G4WORKDIR=/uscms_data/d2/${USER}/g4p/g4.${GEANT_RELEASE}/unmodified/work/SimplifiedCalo" >> run_env_${idx}.txt
    echo "G4WORKDIR=/uscms_data/d2/${USER}/g4p/g4.${GEANT_RELEASE}/unmodified/work/${APPLICATION}" >> run_env_${idx}.txt
      #we may concatenate all log files, but let's keep it last one for now
      cp stdout_${idx}.txt g4p_${SAMPLE_NAME}.log
  fi
done

#post oss data preparation to take advantage of with the current analysis 

echo "... Preparing ossdata_idx_names"
namelist=`ls ${SAMPLE_DIR}/profdata_*_names`
for ff in $namelist ; do
  idx=`echo ${ff} |awk '{split($0,id,"data_"); print id["2"]}' | awk '{split($0,sid,"_name"); print sid["1"]}'`
  tail -n +8 ${ff} | awk '{split($3,fname,"\\(") ; print fname["1"]" "$1" "$2/100.}' | grep -v "cxx17" | \
       head -n 300 | awk '{if(NF==3) print $0}' > ossdata_${idx}_names 
done

echo "... Preparing ossdata_idx_libraries"
liblist=`ls ${SAMPLE_DIR}/profdata_*_libraries`
for ff in $liblist ; do
  idx=`echo ${ff} |awk '{split($0,id,"data_"); print id["2"]}' | awk '{split($0,sid,"_lib"); print sid["1"]}'`
#   tail -n +9 ${ff} | awk '{print $4" "$1" "$2" "$3/100.}' > ossdata_${idx}_libraries 
  tail -n +7 ${ff} | awk '{if ( NF == 4 && $1 ~ /^[0-9]/ && $2 ~ /^[0-9]/) print $4" "$1" "$2" "$3/100.}' > ossdata_${idx}_libraries 
#   extra check/repair for "remains" of mailformed header(s), etc.
  while read line; do
    nwrd=`echo $line | wc -w`
    if [ $nwrd != 4 ]; then 
      if [ $nwrd != 0 ]; then 
        sed -i "s%${line}%%" ossdata_${idx}_libraries
      fi
    fi 
  done < ossdata_${idx}_libraries
  # remove empty lines
  sed -i '/^\s*$/d' ossdata_${idx}_libraries
done

echo "... Preparing ossdata_idx_paths"
pathlist=`ls ${SAMPLE_DIR}/profdata_*_paths`
for ff in $pathlist ; do
  idx=`echo ${ff} |awk '{split($0,id,"data_"); print id["2"]}' | awk '{split($0,sid,"_path"); print sid["1"]}'`
  incl_time=`tail -n +8 ${ff} | head -1 |awk '{print $1}'`
# -->  echo " incl_time = ${incl_time}"
  tail -n +8 ${ff} | awk -v scale=${incl_time} '{split($2,fname,"\\(") ; print fname["1"]" "$1" "$1/scale}' | grep -v "cxx17" | \
       head -n 300 | awk '{if(NF==3) print $0}' > ossdata_${idx}_paths 
# -->  cp profdata_${idx}_paths /work1/g4p/g4p/G4CPT/work/${SAMPLE_NAME}_profdata_${idx}_paths
# -->  cp ossdata_${idx}_paths /work1/g4p/g4p/G4CPT/work/${SAMPLE_NAME}_ossdata_${idx}_paths
done

echo "... Preparing ossdata_idx_hwcsamp"
hwclist=`ls ${SAMPLE_DIR}/profdata_*_hwcsamp`
for ff in $hwclist ; do
  idx=`echo ${ff} |awk '{split($0,id,"data_"); print id["2"]}' | awk '{split($0,sid,"_hwcsamp"); print sid["1"]}'`
#
# --> In earlier releases of OSS the function name was in the 9th position of each line in the output
# --> Apparently since transition to OSS 2.4.1 it moved to 10th position
# --> In principle, if it's always the last position one can use $NF instead of explicit $9 or $10
#
# -->  tail -n +8 ${ff} | awk '{split($9,fname,"\\(") ; if($6 ~ /^[0-9]*$/) print fname["1"]" "$2" "$3/$4" "$3" "$4" "$5" "$6}' | \
  tail -n +8 ${ff} | awk '{split($10,fname,"\\(") ; if($6 ~ /^[0-9]*$/) print fname["1"]" "$2" "$3/$4" "$3" "$4" "$5" "$6}' | \
       grep -v "cxx17" | head -n 300 | awk '{if(NF==7) print $0}' > ossdata_${idx}_hwcsamp 
  nlines=`more ossdata_${idx}_hwcsamp | wc -l`
  if [ $nlines -lt 2 ]; then
    echo "problematic ossdata_${idx}_hwcsamp"
    rm ossdata_${idx}_hwcsamp
# -->    rm ${ff}
  fi
done
#some of hwcsamp output has a null field (empty) for fp_ops, so check that the last field is numeric
#---------------------------------------------------------------------------------------------


echo "... Now READY ${SAMPLE_DIR} ... "

echo "... Proceeding with the R scripts ..."

pushd ${BASE_DIR}

#pwd

#
# NOTE(JVY): Need to find a smater way than explicit path (under spack)
#
path_to_rscript=$(which Rscript)
if [ ! -x "$path_to_rscript" ]; then
echo " Adding path to Rscript "
# PATH=/work1/g4p/g4p/products/spack/opt/spack/linux-scientific7-ivybridge/gcc-8.3.0/r-4.0.2-gsbftm26sqrpj6jjsqljzumj4452vuct/bin:$PATH
 
#
# NOTE: R/Rscript can be setup either way, via just PATH
#       or via full-scale spack load

PATH=/work1/g4p/g4p/products-el8/spack/opt/spack/linux-almalinux8-ivybridge/gcc-11.4.0/r-4.2.2-j33gywwmz5bhv6vzvbdv7mbicdkr57hi/bin:$PATH

# export HOME=/work1/g4p/g4p/products-el8
# export SPACK_ROOT=/work1/g4p/g4p/products-el8/spack
# . ${SPACK_ROOT}/share/spack/setup-env.sh
# spack load r@4.2.2

echo " Rscript: `which Rscript`"
fi



# --> ${BASE_DIR}/analysis/src/oss_make_dataframes.rscript ${SAMPLE_DIR} ${NOHWC}
${SRC_DIR}/oss_make_dataframes.rscript ${SAMPLE_DIR} ${NOHWC}
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Problems generating dataframes ... Cleaning & Aborting ..."
##clean up
rm -f ${SAMPLE_DIR}/profdata_*_*
rm -f ${SAMPLE_DIR}/ossdata_*_*
rm -f ${SAMPLE_DIR}/*.openss
rm -f ${SAMPLE_DIR}/*.txt
rm -f ${SAMPLE_DIR}/*.rda
    exit 1
fi

#//--->this part is working. uncomment the section after testing
#if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
# --> ${BASE_DIR}/analysis/src/make_stepping_dataframe.rscript ${SAMPLE_DIR}
${SRC_DIR}/make_stepping_dataframe.rscript ${SAMPLE_DIR}
#fi
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Problems generating stepping dataframe ... Cleaning & Aborting ..."
##clean up
rm -f ${SAMPLE_DIR}/profdata_*_*
rm -f ${SAMPLE_DIR}/ossdata_*_*
rm -f ${SAMPLE_DIR}/*.openss
rm -f ${SAMPLE_DIR}/*.txt
rm -f ${SAMPLE_DIR}/*.rda
    exit 1
fi

echo "SAMPLE_DIR = ${SAMPLE_DIR}"
echo "NEVENTS = ${NEVENTS}"
# --> ${BASE_DIR}/analysis/src/make_standard_plots_oss.rscript ${SAMPLE_DIR} ${NEVENTS} ${NOHWC}
${SRC_DIR}/make_standard_plots_oss.rscript ${SAMPLE_DIR} ${NEVENTS} ${NOHWC}

RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Problems generating standard plots ... Cleaning & Aborting ..."
##clean up
rm -f ${SAMPLE_DIR}/profdata_*_*
rm -f ${SAMPLE_DIR}/ossdata_*_*
rm -f ${SAMPLE_DIR}/*.openss
rm -f ${SAMPLE_DIR}/*.txt
rm -f ${SAMPLE_DIR}/*.rda
    exit 1
fi
#if [ x"${SAMPLE_NAME}" = x"higgs.FTFP_BERT.1400.4" ]; then
# --> ${BASE_DIR}/analysis/src/make_stepping_plots.rscript ${SAMPLE_DIR} ${NEVENTS}
${SRC_DIR}/make_stepping_plots.rscript ${SAMPLE_DIR} ${NEVENTS}
#fi
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "... Problems generating stepping plots ... Cleaning & Aborting ..."
##clean up
rm -f ${SAMPLE_DIR}/profdata_*_*
rm -f ${SAMPLE_DIR}/ossdata_*_*
rm -f ${SAMPLE_DIR}/*.openss
rm -f ${SAMPLE_DIR}/*.txt
rm -f ${SAMPLE_DIR}/*.rda
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
  	  sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${SRC_DIR}/SimplifiedCaloPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
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
	    sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${SRC_DIR}/SimplifiedCaloPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
#            else
#	    sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/SimplifiedCaloPlots_bySample.html > ${WEB_TAGET_DIR}/index.html
#            fi
	else 
	    echo "Problems creating ${WEB_TAGET_DIR}"
	    echo "Cleaning & Aborting."
##clean up
rm -f ${SAMPLE_DIR}/profdata_*_*
rm -f ${SAMPLE_DIR}/ossdata_*_*
rm -f ${SAMPLE_DIR}/*.openss
rm -f ${SAMPLE_DIR}/*.txt
rm -f ${SAMPLE_DIR}/*.rda
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
  	  sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${SRC_DIR}/cmsExpPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
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
    	      sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${SRC_DIR}/cmsExpPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
#            else
#  	      sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${BASE_DIR}/analysis/src/cmsExpPlots_bySample.html > ${WEB_TAGET_DIR}/index.html
#            fi
	else 
	    echo "Problems creating ${WEB_TAGET_DIR}"
	    echo "Cleaning & Aborting."
##clean up
rm -f ${SAMPLE_DIR}/profdata_*_*
rm -f ${SAMPLE_DIR}/ossdata_*_*
rm -f ${SAMPLE_DIR}/*.openss
rm -f ${SAMPLE_DIR}/*.txt
rm -f ${SAMPLE_DIR}/*.rda
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
  	sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${SRC_DIR}/lArTestPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
    else
	if mkdir ${WEB_TAGET_DIR}
	    then
	    cp ${TAR_DIR}/run_lArTest.g4     ${WEB_TAGET_DIR}/run_lArTest_${SAMPLE_NAME}.g4 
	    cp ${SAMPLE_DIR}/run_lArTest_${SAMPLE_NAME}_g4.cfg ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/stdout_1_1.txt            ${WEB_TAGET_DIR}/run_lArTest_${SAMPLE_NAME}.log 
	    cp ${SAMPLE_DIR}/prof_*.png ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.csv ${WEB_TAGET_DIR}
	    cp ${SAMPLE_DIR}/prof_*.html ${WEB_TAGET_DIR}
    	    sed "s/G4P_SAMPLE_NAME/${SAMPLE_NAME}/" ${SRC_DIR}/lArTestPlots_bySampleExt.html > ${WEB_TAGET_DIR}/index.html
	else 
	    echo "Problems creating ${WEB_TAGET_DIR}"
	    echo "Cleaning & Aborting."
##clean up
rm -f ${SAMPLE_DIR}/profdata_*_*
rm -f ${SAMPLE_DIR}/ossdata_*_*
rm -f ${SAMPLE_DIR}/*.openss
rm -f ${SAMPLE_DIR}/*.txt
rm -f ${SAMPLE_DIR}/*.rda
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
