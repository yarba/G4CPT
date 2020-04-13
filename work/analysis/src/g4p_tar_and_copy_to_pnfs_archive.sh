#!/usr/bin/env bash

dCache=/pnfs/geant4/archive/g4p/cpu_memory_profiling/pbs
PBS_DIR=/lfstev/g4p/g4p/pbs

CURRENT_DIR=${PWD}

PROJ_NAME=${1}
# --> testing --> PROJ_NAME="oss_10.6.r03_SimplifiedCalo_01"

cd ${PBS_DIR}
echo "I have moved to ${PWD} "
if [ -d ${PROJ_NAME} ]; then
   echo "tarball = ${PROJ_NAME}.tar"
   /bin/tar -cf ${PROJ_NAME}.tar ${PROJ_NAME}
   /usr/bin/dccp ${dv}.tar ${dCache}/.
   /bin/rm ${PROJ_NAME}.tar
fi
cd ${CURRENT_DIR}

