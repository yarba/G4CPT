#! /bin/bash
#
# A script to run Mu2e framework jobs on the grid.
#
# It takes 5 arguments:
#   cluster    - the condor job cluster number
#   process    - the condor job process number, within the cluster
#   user       - the username of the person who submitted the job
#   submitdir  - the directory from which the job was submitted ( not used at this time).
#   outstagebase - 
#
# Outputs:
#  - All output files are created in the grid working space.  At the end of the job
#    all files in this directory will be copied to:
#      /grid/data/mu2e/outstage/$user/${cluster}_${process}
#    This includes a copy of any input files that the user does not first delete.
#
# Notes:
#
# 1) For documentation on using the grid, see
#      http://mu2e.fnal.gov/atwork/computing/fermigrid.shtml
#    For details on cpn and outstage see:
#      http://mu2e.fnal.gov/atwork/computing/fermigrid.shtml#cpn
#      http://mu2e.fnal.gov/atwork/computing/fermigrid.shtml#outstage
#
# 2) To test if there are files to move from the original current working 
#    directory to the self destructing working directory, we use
#
#      if (( $( ls -1 $ORIGDIR | wc -l) > 0 )); then ... ; fi
#
#    This is potentially fragile.  If a user aliases or otherwise redefines
#    ls, this may fail.  Unfortunately the grid worker nodes do not let
#    us write /bin/ls instead of plain ls.  If we do, then we get an
#    error 
#
#       ls: write error: Broken pipe
#
#    So we are living with the fragile code.
#

# Copy arguments into meaningful names.
cluster=$1
process=$2
user=$3
submitdir=$4
outstagebase=$5
echo "Input arguments:"
echo "Cluster:    " $cluster
echo "Process:    " $process
echo "User:       " $user
echo "SubmitDir:  " $submitdir
echo "Outstage base directory: " $outstagebase
echo " "

QUEUE_ID=$2

#-----------------------------------------------------------------------
#
# Make sure we have the expected arguments and environment variables
#
if [ -z ${QUEUE_ID} ]
then
  echo "Process argument is required"
  exit 1
fi

# Do not change this section.
# It creates a temporary working directory that automatically cleans up all
# leftover files at the end.
ORIGDIR=`pwd`
TMP=`mktemp -d ${OSG_WN_TMP:-/var/tmp}/working_dir.XXXXXXXXXX`
TMP=${TMP:-${OSG_WN_TMP:-/var/tmp}/working_dir.$$}

{ [[ -n "$TMP" ]] && mkdir -p "$TMP"; } || \
  { echo "ERROR: unable to create temporary directory!" 1>&2; exit 1; }
trap "[[ -n \"$TMP\" ]] && { cd ; rm -rf \"$TMP\"; }" 0
cd $TMP

# If there are files in the original grid working directory, move them to the new directory.
# Fragile!!! See note 2.
if (( $( ls -1 $ORIGDIR | wc -l) > 0 )); then
 mv $ORIGDIR/* .
fi
# End of the section you should not change.

# Directory in which to put the output files.
outstage=${outstagebase}/$user

# This is needed because of pollution from setup vdt in the submitting environment.
unset LD_LIBRARY_PATH

# Establish environment.
source /grid/fermiapp/products/mu2e/setupmu2e-art.sh
source /grid/fermiapp/mu2e/users/genser/geant4work/g4.9.4.p01_mu2e_v1_0_9/unmodified/Offline/setup.sh
source /grid/fermiapp/mu2e/users/genser/geant4work/g4.9.4.p01_mu2e_v1_0_9/unmodified/Offline/bin/addlocal.sh
source /grid/fermiapp/mu2e/users/genser/fast/bin/etc/setup

# Construct the run-time configuration file for this job;
# Make the random number seeds a function of the process number.
# Run number of the generated events will be the process number.
generatorSeed=$(( $process * 23 + 31))
g4Seed=$(( $process * 41 + 37))
makeSHSeed=$(( $process * 43 + 57))
runNumber=$(( $process + 1))
cp /grid/fermiapp/mu2e/users/genser/geant4work/g4.9.4.p01_mu2e_v1_0_9/unmodified/Offline/Mu2eG4/test/g4test_03.fcl prof.fcl
echo "physics.producers.generate.seed : [ " $generatorSeed " ]" >> prof.fcl
echo "physics.producers.g4run.seed :    [ " $g4Seed        " ]" >> prof.fcl
echo "physics.producers.makeSH.seed :   [ " $makeSHSeed    " ]" >> prof.fcl
# 10000/24min with unoptimized art
echo "source.maxEvents : "                  10000               >> prof.fcl
echo "source.firstRun  : "                  $runNumber          >> prof.fcl

# Stage large input files to local disk.
#mkdir -p ExampleDataFiles/StoppedMuons
#/grid/fermiapp/minos/scripts/cpn \
#     /grid/fermiapp/mu2e/DataFiles/ExampleDataFiles/StoppedMuons/stoppedMuons_02.txt \
#     ExampleDataFiles/StoppedMuons/stoppedMuons_02.txt

ulimit -a

if ulimit -c unlimited -S
then
    echo "ulimit -c unlimited -S worked"
fi

ulimit -a

for LOOP in 1
do
  QLOOP=${QUEUE_ID}_${LOOP}
  NOTE_FILE=note_g4profiling_${QLOOP}
  echo "Loop begin at: `date`"                   > ${NOTE_FILE}
  echo "Scratch dir is: ${_CONDOR_SCRATCH_DIR}" >> ${NOTE_FILE}

  cat /proc/cpuinfo /proc/meminfo    > run_env_${QLOOP}.txt
  echo "nodename: `uname -n`"       >> run_env_${QLOOP}.txt
  echo "kernel_version: `uname -r`" >> run_env_${QLOOP}.txt
  echo "processor_type: `uname -p`" >> run_env_${QLOOP}.txt
  printenv                          >> run_env_${QLOOP}.txt

  echo "run begin: `date`" > tmp_trialdata.txt
# Run the Offline job.
  profrun -s mu2e -c prof.fcl > tmp.stdout 2> tmp.stderr &
  PROC_ID=$!

  echo "process id is: ${PROC_ID}"       >> ${NOTE_FILE}

  ps xjfwww                         >> run_env_${QLOOP}.txt

  mv tmp_trialdata.txt trialdata_${QLOOP}.txt
  mv tmp.stdout stdout_${QLOOP}.txt
  mv tmp.stderr stderr_${QLOOP}.txt

  wait ${PROC_ID}
  echo "run end: `date`"         >> trialdata_${QLOOP}.txt

  echo "doing ls -la" >> stdout_${QLOOP}.txt
  ls -la        >> stdout_${QLOOP}.txt

  echo "doing ls -la" >> run_env_${QLOOP}.txt
  ls -la        >> run_env_${QLOOP}.txt


  # well ${PROC_ID} is a parent id, not the actuall process itself...; 

  # standard profiling data

  # suffixes="condfile debugging libraries maps names paths sample_info totals"
  suffixes="libraries maps names paths totals debugging"

  for suffix in $suffixes
    do
    for ff in profdata_*_*_*_${suffix}
      do
      fff=${ff#profdata_${QLOOP}_${suffix}}
      if [ $ff = $fff ] 
	  then
	  if [ -f ${fff} ]
	      then
	      echo "doing mv ${fff} profdata_${QLOOP}_${suffix}" >> run_env_${QLOOP}.txt
	      mv ${fff} profdata_${QLOOP}_${suffix}
	  else
	      touch     profdata_${QLOOP}_${suffix}
	  fi
      fi
    done
  done

  # sar data

  suffixes="cpu ctxswitch interrupts io load memory memrates paging sar swapping"
  for suffix in $suffixes
    do
    for ff in profdata_*_${suffix}
      do
      fff=${ff#profdata_${QLOOP}_${suffix}}
      if [ $ff = $fff ] 
	  then
	  if [ -f ${fff} ]
	      then
	      echo "doing mv ${fff} profdata_${QLOOP}_${suffix}" >> run_env_${QLOOP}.txt
	      mv ${fff} profdata_${QLOOP}_${suffix}
	  else
	      touch     profdata_${QLOOP}_${suffix}
	  fi
      fi
    done
  done

  # need to make sure to not to rename previosly renamed files...

  for ff in profdata_*_*
    do
    fff=${ff#profdata_${QLOOP}}
    if [ $ff = $fff ]
	then
	if [ -f ${fff} ]
	    then
	    echo "doing mv ${ff}  profdata_${QLOOP}" >> run_env_${QLOOP}.txt
	    mv ${ff}  profdata_${QLOOP}
	else
	    touch  profdata_${QLOOP}
	fi
    fi
  done

  # one still needs to mv output root file the name needs to be the same as in the _cfg.py file

  if [ -f data_03.root ]
  then
      rm data_03.root
  fi

  if [ -f g4test_03.root ]
  then
      rm g4test_03.root
  fi

#  # test for non-empty names file
#  if [ -s profdata_${QLOOP}_names ]; then
#    # unmangle the function names and tack them on the end of each line
#    cut -f 9 profdata_${QLOOP}_names | c++filt | paste profdata_${QLOOP}_names - > profdata_${QLOOP}_temp
#    mv profdata_${QLOOP}_temp profdata_${QLOOP}_names
#  fi

  grep 'TimeModule>' stdout_${QLOOP}.txt  > moduledata_${QLOOP}.txt
  grep 'TimeEvent>'  stdout_${QLOOP}.txt  > eventdata_${QLOOP}.txt
  grep 'TimeReport>' stdout_${QLOOP}.txt >> trialdata_${QLOOP}.txt
  grep 'NodeLoad>'   stdout_${QLOOP}.txt  > nodeload_${QLOOP}.txt

  echo "after run"                       >> run_env_${QLOOP}.txt
  printenv                               >> run_env_${QLOOP}.txt

  TAR_FILE=g4profiling_${QLOOP}.tgz
  #mv prof.fcl thisjob_${QLOOP}.fcl
  tar zcf ${TAR_FILE}  profdata_${QLOOP}_* *.txt profdata_${QLOOP} *.fcl
  rm -f *.txt *.fcl
  rm -f profdata_${QLOOP}_*
  rm -f profdata_${QLOOP}

  echo "tar file for this loop: ${TAR_FILE}" >> ${NOTE_FILE}
  echo "PID for this loop: ${PROC_ID}"       >> ${NOTE_FILE}
  echo "Loop end at: `date`"                 >> ${NOTE_FILE}
done

#assuming only one core file
for ff in core.*
  do
  fff=${ff#core_${QLOOP}}
  if [ $ff = $fff ]
      then
      if [ -f ${fff} ]
	  then
	  mv ${ff}  core_${QLOOP}
      fi
  fi
done

# Remove any files that should not be copied to the output staging area.
# Subdirectories will not be copied so there is no need to delete them.

# Create a directory in the output staging area.
/grid/fermiapp/mu2e/bin/createOutStage.sh ${cluster} ${process} ${user} ${outstagebase}

# Copy all files from the working directory to the new directory in the output staging area.
# This will not copy subdirectories.
/grid/fermiapp/minos/scripts/cpn * ${outstage}/${cluster}/${cluster}_${process}

exit 0
