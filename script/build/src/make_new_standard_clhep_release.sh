#!/bin/bash

# svn keywords:
# $Rev: 714 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2011-03-24 15:10:28 -0500 (Thu, 24 Mar 2011) $: Date of last commit

# script to build stand alone CLHEP

# TODO: Move this to g4 directory, preparing for move out of perfdb.

trap "echo 'Exiting due to user interrupt' && exit" INT

OUR_NODENAME=`uname -n`

if [ ${OUR_NODENAME} != "cmssrv140.fnal.gov" ] && [ ${OUR_NODENAME} != "cmssrv140.fnal.gov" ]
then
   echo This script expects to be run on cmssrv140.fnal.gov
   exit 1
fi

if [ $# -ne 1 ]
then
    echo "Wrong number of arguments"
    echo "Must supply CLHEP release number (e.g. 2.1.0.1)"
    exit 1
fi

CLHEP_RELEASE=$1

echo "${0} called   with $1 $2 $3 $4 $5 $6 $7"

#echo "CLHEP release is: ${CLHEP_RELEASE}"

#-----------------------------------------------------------------------
# Move to the right directory to do all the work.
#-----------------------------------------------------------------------

if [ ${OUR_NODENAME} = "cmssrv140.fnal.gov" ]
then
    HERE=/storage/local/data1/geant4work
fi

if pushd ${HERE}
then
   echo We are now in $PWD
else
   echo Failed to move to directory ${HERE}
   exit 1
fi

TARBALL="${HERE}/download/clhep\-${CLHEP_RELEASE}.tgz"

if [ ! -f ${TARBALL} ]
then
    echo "TARBALL is set to ${TARBALL}"
    echo "This file does not exist; aborting."
    exit 1
fi

# Adjust umask to that files are created with group read/write
umask 0002

#echo "debug exit"
#exit 11

#-----------------------------------------------------------------------
# Work starts here.
#-----------------------------------------------------------------------

# check if not there already
TOPDIR="${HERE}/clhep/${CLHEP_RELEASE}"

if [ -d ${TOPDIR} ]
then
    echo "${TOPDIR} directory already exists, rename it or remove it before continuing"
    echo "Aborting."
    exit 1
fi

#-----------------------------------------------------------------------
# Untar source 
pushd ${HERE}/clhep
echo "In ${HERE}, untarring ${TARBALL}"
tar zxf ${TARBALL}

# Change permissions for everything to group read/write
echo Changing permissions under ${TOPDIR}
chmod -R g+rw ${TOPDIR}

pushd ${TOPDIR}/CLHEP

./configure --prefix ${HERE}/clhep/${CLHEP_RELEASE}

make -j 8

make install

exit
