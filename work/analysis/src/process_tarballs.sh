#!/bin/bash

# svn keywords:
# $Rev: 714 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-03-24 15:10:28 -0500 (Thu, 24 Mar 2011) $: Date of last commit

# TODO: Move this to profiling-specific directory, preparing for move out of perfdb.

trap "echo 'Exiting due to user interrupt' && exit" INT

OUR_NODENAME=`uname -n`

HOST_NODE="oink.fnal.gov"

if [ ${OUR_NODENAME} != ${HOST_NODE} ]
then
   echo This script expects to be run on ${HOST_NODE}
   exit 1
fi

OVERWRITE="NO"

while getopts "f" opt; do
    echo $0: processing option: $opt
    case $opt in
	f ) OVERWRITE="YES" ;;
       \? ) echo "Usage: $0 [-f] args"
            exit 1
    esac
done

shift $(($OPTIND - 1))

echo "${0}: called with $1 $2 $3 $4 $5 $6 $7"

if ( [ $# -ne 5 ] && [ $# -ne 6 ] ) || [ $# -eq 6 ] && [ $1 != "-f" ]
then
    echo "Wrong number of arguments $#"
    echo "Must supply experiment number e.g. 60"
    echo "GEANT release number (e.g. 9.4.p01)"
    echo "Application (e.g. SimplifiedCalo or cmssw426 or mu2e109)"
    echo "Expected number of events (e.g. 100)"
    echo "and minimum tarball size in bytes (e.g. 190000)"
    echo "if using -f it must be the first argument "
    exit 1
fi

EXPERIMENT_NUMBER=$1

GEANT_RELEASE=$2

APPLICATION=$3

MINIMUM_TARBALLSIZE=$5
# in bytes

EXPECTED_NUMBER_OF_EVENTS=$4

BASE_DIR=~/g4p

WEB_DIR=~/webpages/g4p

#-----------------------------------------------------------------------
# Move to the right directory to do all the work.
#-----------------------------------------------------------------------

PROJECT=g4.${GEANT_RELEASE}_${APPLICATION}_${EXPERIMENT_NUMBER}

PROJECT_DIR=${BASE_DIR}/${PROJECT}

EXP_DIR=${BASE_DIR}/g4.${GEANT_RELEASE}_${APPLICATION}_${EXPERIMENT_NUMBER}/exp_${EXPERIMENT_NUMBER}

if pushd ${EXP_DIR}
then
   echo We are now in $PWD
else
   echo Failed to move to directory ${EXP_DIR}
   exit 1
fi

# checking if the web page directory does not exists already
# (may need to introduce a "force" parameter)

if [ -d ${WEB_DIR}/${PROJECT} ] && [ ${OVERWRITE} != "YES" ]
then
    echo "Direcory ${WEB_DIR}/${PROJECT} exists already"
    echo "OVERWRITE=${OVERWRITE}"
    echo "Aborting."
    echo "Use -f as the first argument to overwrite files in it"
    exit 1
fi

# Adjust umask to that files are created with group read/write
umask 0002

#echo "debug exit"
#exit 11

#-----------------------------------------------------------------------
# Work starts here.
#-----------------------------------------------------------------------

# we are docummenting the tarball sizes:
echo "Largest tarballs:"
echo ""
ls -laS g4profiling_*tgz| head
echo ""
echo "Smallest tarballs:"
echo ""
ls -laS g4profiling_*tgz| tail
echo ""

echo "Counting tarballs"
TARBALL_NUMBER=`for ff in \`find . -name g4profiling_\*_\*.tgz -size +${MINIMUM_TARBALLSIZE}c -print\`; do ls -la $ff; done | wc -l`
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "Could not count tarballs"
    echo "Aborting."
    exit 1
fi
echo "We have ${TARBALL_NUMBER} tarballs with the size greater than ${MINIMUM_TARBALLSIZE} bytes"

if [ ${TARBALL_NUMBER} -lt 1 ]
then
    echo "Too few tarballs"
    echo "Aborting."
    exit 1
fi

echo "Untarring tarballs"
RESULT=`for ff in \`find . -name g4profiling_\*_\*.tgz -size +${MINIMUM_TARBALLSIZE}c -print\`; do tar xzf $ff; done`
if (( ${RETURN_CODE} )) ;
then
    echo "Could not untar tarballs"
    echo "Aborting."
    exit 1
fi

echo "Counting non empty trialdata_*.txt files"
TDTXT_NUMBER=`egrep "TimeReport> Time report complete in " trialdata_*.txt | wc -l`
echo "We have ${TDTXT_NUMBER} of non empty trialdata_*.txt files"


if [ ${TARBALL_NUMBER} -ne  ${TDTXT_NUMBER} ]
then
    echo "Inconsitend number of tarballs and non empty trialdata_*.txt files ${TARBALL_NUMBER},  ${TDTXT_NUMBER} "
    echo "Aborting."
    exit 1
fi

echo "Counting good trialdata_*.txt files"
TDTXT_GOOD_NUMBER=`grep "TimeEvent> ${EXPECTED_NUMBER_OF_EVENTS} " eventdata_*.txt | wc -l`
echo "We have ${TDTXT_GOOD_NUMBER} of trialdata_*.txt files with ${EXPECTED_NUMBER_OF_EVENTS} events"

if [ ${TARBALL_NUMBER} -ne  ${TDTXT_GOOD_NUMBER} ]
then
    echo "Inconsitend number of tarballs and good trialdata_*.txt files "
    echo "Aborting."
    exit 1
fi

echo "Making sure the names file are not empty"
PD_NONEMPTY_NUMBER=`find . -name profdata_\*_\*_names -size +1c -print | wc -l`
echo "We have ${PD_NONEMPTY_NUMBER} of nonempty profdata_*_*_names files"

if [ ${TARBALL_NUMBER} -ne  ${PD_NONEMPTY_NUMBER} ]
then
    echo "Inconsitend number of tarballs and nonempty profdata_*_1_names files ${TARBALL_NUMBER},  ${PD_NONEMPTY_NUMBER}"
    echo "Aborting."
    exit 1
fi


echo "Proceeding with the R scripts"

pushd ${BASE_DIR}

pwd

${BASE_DIR}/analysis/src/make_dataframes.rscript ${PROJECT_DIR}
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "Problems generating dataframes"
    echo "Aborting."
    exit 1
fi


${BASE_DIR}/analysis/src/make_standard_plots.rscript ${PROJECT_DIR}
RETURN_CODE=$?
if (( ${RETURN_CODE} )) ;
then
    echo "Problems generating plots"
    echo "Aborting."
    exit 1
fi

echo "Copying plots to the web pages area:"
echo "${WEB_DIR}/${PROJECT}"

pwd

APPLHEAD=${APPLICATION:0:4}

echo ${APPLHEAD}

if [ ${APPLHEAD} = "Simp" ]
    then
    grep ^\/ ${EXP_DIR}/run_SimplifiedCalo.g4 > ${EXP_DIR}/run_SimplifiedCalo_g4.txt
    if [ -d ${WEB_DIR}/${PROJECT} ]
	then
	cp ${EXP_DIR}/run_SimplifiedCalo.g4     ${WEB_DIR}/${PROJECT}
	cp ${EXP_DIR}/run_SimplifiedCalo_g4.txt ${WEB_DIR}/${PROJECT}
	cp ${PROJECT_DIR}/prof_*.png ${WEB_DIR}/${PROJECT}
	cp ${PROJECT_DIR}/prof_*.html ${WEB_DIR}/${PROJECT}
	cp ${BASE_DIR}/analysis/src/SimplifiedCaloPlots.html ${WEB_DIR}/${PROJECT}/index.html
    else
	if mkdir ${WEB_DIR}/${PROJECT}
	    then
	    cp ${EXP_DIR}/run_SimplifiedCalo.g4     ${WEB_DIR}/${PROJECT}
	    cp ${EXP_DIR}/run_SimplifiedCalo_g4.txt ${WEB_DIR}/${PROJECT}
	    cp ${PROJECT_DIR}/prof_*.png ${WEB_DIR}/${PROJECT}
	    cp ${PROJECT_DIR}/prof_*.html ${WEB_DIR}/${PROJECT}
	    cp ${BASE_DIR}/analysis/src/SimplifiedCaloPlots.html ${WEB_DIR}/${PROJECT}/index.html
	else 
	    echo "Problems creating ${WEB_DIR}/${PROJECT}"
	    echo "Aborting."
	    exit 1
	fi
    fi
fi
if [ ${APPLHEAD} = "cmss" ]
    then
    if [ -d ${WEB_DIR}/${PROJECT} ]
	then
	cp ${EXP_DIR}/run_sim_*_cfg.py     ${WEB_DIR}/${PROJECT}
	cp ${PROJECT_DIR}/prof_*.png ${WEB_DIR}/${PROJECT}
	cp ${PROJECT_DIR}/prof_*.html ${WEB_DIR}/${PROJECT}
	cp ${BASE_DIR}/analysis/src/cmsswPlots.html ${WEB_DIR}/${PROJECT}/index.html
    else
	if mkdir ${WEB_DIR}/${PROJECT}
	    then
	    cp ${EXP_DIR}/run_sim_*_cfg.py ${WEB_DIR}/${PROJECT}
	    cp ${PROJECT_DIR}/prof_*.png ${WEB_DIR}/${PROJECT}
	    cp ${PROJECT_DIR}/prof_*.html ${WEB_DIR}/${PROJECT}
	    cp ${BASE_DIR}/analysis/src/cmsswPlots.html ${WEB_DIR}/${PROJECT}/index.html
	else 
	    echo "Problems creating ${WEB_DIR}/${PROJECT}"
	    echo "Aborting."
	    exit 1
	fi
    fi
    CFGAUX=g4.${GEANT_RELEASE}_${APPLICATION}
    sed -i~ "s/run_SimplifiedCalo.g4/run_sim_${CFGAUX//./}_cfg.py/g" ${WEB_DIR}/${PROJECT}/index.html
fi
if [ ${APPLHEAD} = "mu2e" ]
    then
    if [ -d ${WEB_DIR}/${PROJECT} ]
	then
	cp ${EXP_DIR}/prof.fcl     ${WEB_DIR}/${PROJECT}
	cp ${PROJECT_DIR}/prof_*.png ${WEB_DIR}/${PROJECT}
	cp ${PROJECT_DIR}/prof_*.html ${WEB_DIR}/${PROJECT}
	cp ${BASE_DIR}/analysis/src/mu2ePlots.html ${WEB_DIR}/${PROJECT}/index.html
    else
	if mkdir ${WEB_DIR}/${PROJECT}
	    then
	    cp ${EXP_DIR}/prof.fcl ${WEB_DIR}/${PROJECT}
	    cp ${PROJECT_DIR}/prof_*.png ${WEB_DIR}/${PROJECT}
	    cp ${PROJECT_DIR}/prof_*.html ${WEB_DIR}/${PROJECT}
	    cp ${BASE_DIR}/analysis/src/mu2ePlots.html ${WEB_DIR}/${PROJECT}/index.html
	else 
	    echo "Problems creating ${WEB_DIR}/${PROJECT}"
	    echo "Aborting."
	    exit 1
	fi
    fi
fi

echo "All done"

exit
