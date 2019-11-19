#!/bin/sh

#setup cmsenv
if [ -z "${CMS_PATH}" ] ; then 
  source /uscmst1/prod/sw/cms/shrc prod
fi

cd G4P_CMSSW_SRC_DIR
eval `scramv1 runtime -sh`
