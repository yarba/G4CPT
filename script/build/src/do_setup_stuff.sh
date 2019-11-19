#!/bin/bash

# svn keywords:
# $Rev: 746 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-08-12 13:05:27 -0500 (Fri, 12 Aug 2011) $: Date of last commit

# TODO: Move this to CMS-specific directory, preparing for move out of perfdb.

#-----------------------------------------------------------------------
# This script is run by fix_tool_description.
#-----------------------------------------------------------------------
CMSSW_SANDBOX=$1
GEANT_RELEASE=$2
cd ${CMSSW_SANDBOX}

echo "PWD:           ${PWD}"
echo "Geant release: ${GEANT_RELEASE}"
echo "CMSSW_SANDBOX: ${CMSSW_SANDBOX}"
echo "SCRAM_TOOL_HOME ${SCRAM_TOOL_HOME}"

if ! type -p scramv1 >&/dev/null
then
    source /uscmst1/prod/sw/cms/bashrc prod
fi

export SCRAM_ARCH=`scramv1 arch`
#export SCRAM_ARCH=`cmsarch`

echo "SCRAM_ARCH:    ${SCRAM_ARCH}"

#scramv1 setup geant4     && scramv1 setup ${CMSSW_SANDBOX}geant4_tool.xml     && scramv1 build ToolUpdated_geant4
#scramv1 setup geant4core && scramv1 setup ${CMSSW_SANDBOX}geant4core_tool.xml && scramv1 build ToolUpdated_geant4core

scramv1 setup geant4     && scramv1 build ToolUpdated_geant4
scramv1 setup geant4core && scramv1 build ToolUpdated_geant4core
scramv1 setup geant4data && scramv1 build ToolUpdated_geant4data

STATUS=$?
echo "Status: ${STATUS}"
exit $STATUS

