#!/bin/bash 

# svn keywords:
# $Rev: 1 $: Revision of last commit
# $Author: syjun $: Author of last commit
# $Date: 2011-10-28 09:10:28 $: Date of last commit

#-------------------------------------------------------------------------------
# copy geant4 and application to condor and fix environment variables
#-------------------------------------------------------------------------------
if [ $# -lt 7 ]; then
  echo -e "\nUsage: g4p_create_experiment.sh G4P_EXP_NUM G4P_DATA_DIR \
    G4P_BLUEARC_DIR G4P_SPOOL_DIR G4P_RAMDISK_DIR G4P_GEANT4_RELEASE \
    G4P_APPLICATION_NAME [G4P_APPLICATION_RELEASE]" 
  exit 1
fi

EXP_NUM=$1
INPUT_DIR=$2
BLUEARC_DIR=$3
SPOOL_DIR=$4
RAMDISK_DIR=$5
GEANT4_RELEASE=$6
APPLICATION_NAME=$7
APPLICATION_RELEASE=$8

g4prefix=g4
geant4prefix=geant4
app_exe_name=${APPLICATION_NAME}

if [[ ${APPLICATION_NAME} =~ "VG" ]]; then
g4prefix=g4vg
geant4prefix=geant4vg
app_exe_name=${APPLICATION_NAME%%VG*}
fi

#-------------------------------------------------------------------------------
# tarball
#-------------------------------------------------------------------------------
tar_dir=${BLUEARC_DIR}/build/${g4prefix}.${GEANT4_RELEASE}
tar_name=${geant4prefix}.${GEANT4_RELEASE}.${APPLICATION_NAME}.tar.gz
#-------------------------------------------------------------------------------
# Prepare pbs jobs for applications
#-------------------------------------------------------------------------------

unset g4p_dir ; unset exp_exe ; unset exp_cfg ; unset exp_inp ; unset exp_env

if [ x"${APPLICATION_NAME}" = x"SimplifiedCalo" -o \
     x"${APPLICATION_NAME}" = x"cmsExp" -o \
     x"${APPLICATION_NAME}" = x"cmsExpVG" -o \
     x"${APPLICATION_NAME}" = x"lArTest" -o \
     x"${APPLICATION_NAME}" = x"SimplifiedCaloMT" -o \
     x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then

  g4p_dir=${RAMDISK_DIR}/${g4prefix}.${GEANT4_RELEASE}
  exp_exe=${app_exe_name}
  exp_cfg="run_${app_exe_name}.g4"
  exp_inp="hepevt.data"
  exp_env="${g4p_dir}/${APPLICATION_NAME}"
else
  echo "... No g4p experiment for ${APPLICATION_NAME} ..." ; exit 1
fi

#------------------------------------------------------------------------------
# Create directory for the g4p experiment number
#------------------------------------------------------------------------------

exp_dir=${BLUEARC_DIR}/pbs/oss_${GEANT4_RELEASE}_${APPLICATION_NAME}_${EXP_NUM}

if [ -d ${exp_dir} ]; then
  echo "... exp, ${exp_dir} already exists! ..."
  echo "... Do you want to overwrite the directory? Answer [no|yes]"
  unset confirm; read confirm
  if [ x"$confirm" = x"yes" ]; then 
    echo "... Removing the experiment and creating a new one ... "
    rm -rf  ${exp_dir}
  else 
    echo "... Creating a new experiment cancelled ..." ; exit 1
  fi
fi

# check cofiguration area
cfg_dir="${PWD}/../cfg"
if [ ! -d ${cfg_dir}  ]; then
  echo "... Wrong path for configuration, ${cfg_dir} ..." ; exit 1
fi

#------------------------------------------------------------------------------
# generate files for condor (jdl, sh, g4)
#------------------------------------------------------------------------------
unset template_submit
unset template_master
unset template_tool
node_name=`uname -n`

unset g4p_sample_list
if [ x"${APPLICATION_NAME}" = x"lArTest" ]; then
  g4p_sample_list=`grep G4P_LARTEST g4p.init | awk '{print $3}'`
elif [[ ${APPLICATION_NAME} =~ "VG" ]]; then
g4p_sample_list="higgs.FTFP_BERT.1400.4"
else 
  g4p_sample_list=`grep G4P_SAMPLE g4p.init | awk '{print $3}'`
fi

#loop over tools
# for tool in osspcsamp ossusertime osshwcsamp osshwcsamp2 igprof ; do
for tool in osspcsamp ossusertime osshwcsamp igprof ; do

  # Jan.2021 migration to WC-IC
  template_submit="${cfg_dir}/template.wcic_queue_${tool}"
  
  #if [ -f ${template_submit} ]; then
  #else 
  #  echo "... ${template_submit} could not be located properly ..."
  #fi

  template_master="${cfg_dir}/template.wcic_run_master"
  
  template_tool="${cfg_dir}/template.wcic_run_${tool}"
  
  if [ ! -f ${template_tool} ]; then
    echo "...  ${template_tool} doesn't exist ..." ; exit 1
  fi

  #loop over sample
  for sample in ${g4p_sample_list} ; do

    exp_procpid=`echo ${sample} |awk '{split($0,ss,"."); print ss["1"]}'`
    exp_physics=`echo ${sample} |awk '{split($0,ss,"."); print ss["2"]}'`
    exp_energy=`echo ${sample}  |awk '{split($0,ss,"."); print ss["3"]}'`
    exp_bfield=`echo ${sample}  |awk '{split($0,ss,"."); print ss["4"]}'`
    
    if [[ ${exp_energy} == *"MeV"* ]]; then
       ene=${exp_energy%%"MeV"*}
       exp_energy="${ene} MeV"
    fi
    
    #save 
    exp_sample=${exp_procpid}

    if [ x"${exp_procpid}" = x"higgs" -o x"${exp_procpid}" = x"e-100MeV" ]; then
      exp_gentype="hepEvent"
      exp_nloops=`grep G4P_NUM_LOOPS_HEPEVT g4p.init | awk '{print $3}'`
      exp_nqueue=`grep G4P_NUM_QUEUE_HEPEVT g4p.init | awk '{print $3}'`
      exp_nevent=`grep G4P_NUM_EVENT_HEPEVT g4p.init | awk '{print $3}'`
      exp_igntot=`expr $exp_nevent + 1`
      exp_procpid="e-"
    else
      exp_gentype="particleGun"
      exp_nloops=`grep G4P_NUM_LOOPS_PGUN g4p.init | awk '{print $3}'`
      exp_nqueue=`grep G4P_NUM_QUEUE_PGUN g4p.init | awk '{print $3}'`
      exp_nevent=`grep G4P_NUM_EVENT_PGUN g4p.init | awk '{print $3}'`

# --->      if [ x"${APPLICATION_NAME}" = x"cmsExp" ]; then
      if [[ ${APPLICATION_NAME} =~ "cmsExp" ]]; then
        exp_igntot=`expr $exp_nevent / 10 + 1`
      else
        exp_igntot=`expr $exp_nevent / 2 + 1`
      fi

      #scale number of events for 1GeV and 5GeV
      if [ x"${APPLICATION_NAME}" = x"lArTest" ]; then
          exp_nevent=`expr $exp_nevent / 2`
      else
        if [ x"${exp_energy}" = x"1" ]; then
          exp_nevent=`expr $exp_nevent \* 10`
        fi
        if [ x"${exp_energy}" = x"5" ]; then
          exp_nevent=`expr $exp_nevent \* 2`
        fi
	if [ x"${exp_energy}" = x"250 MeV" ]; then
	   exp_nevent=`expr $exp_nevent \* 10`
	fi
      fi
    fi      

    work_dir=${exp_dir}/${tool}/${sample}
    mkdir -p ${work_dir} && echo "... Creating, ${work_dir} ..."

    #local disk on the worker
    spool_dir=${SPOOL_DIR}/${tool}_${sample}

    # generate condor jdl file
    submit_jdl="${work_dir}/submit_${tool}"
    tool_master="${work_dir}/master_${tool}.sh"
    tool_sh="${work_dir}/run_${tool}.sh"
    sps_cfg="${work_dir}/${exp_cfg}"

    # submit script
    sed    "s%G4P_OUTPUT_DIR%${work_dir}%"  ${template_submit} > ${PWD}/tmp_submit_${tool}
    sed -i "s%G4P_RUN_MASTER%${tool_master}%"    ${PWD}/tmp_submit_${tool}
    sed -i "s%G4P_RUN_SHELL%${tool_sh}%"    ${PWD}/tmp_submit_${tool}

    # SLURM master exec
    sed  "s%G4P_RAMDISK_DIR%${RAMDISK_DIR}%" ${template_master} > ${PWD}/tmp_master_${tool}.sh
    sed -i "s%G4P_TARBALL_DIR%${tar_dir}%"      ${PWD}/tmp_master_${tool}.sh
    sed -i "s%G4P_TARBALL_NAME%${tar_name}%"    ${PWD}/tmp_master_${tool}.sh
    
    #substitute parameters of template (template.run_sprof)
    sed    "s%G4P_APPLICATION_EXE%${exp_exe}%"  ${template_tool} > ${PWD}/tmp_run_${tool}.sh
    sed -i "s%G4P_APPLICATION_CFG%${exp_cfg}%"  ${PWD}/tmp_run_${tool}.sh
    sed -i "s%G4P_APPLICATION_DIR%${exp_env}%"  ${PWD}/tmp_run_${tool}.sh
    if [[ ${exp_physics} == *"_Auger"*  ]]; then
       phys=${exp_physics%%"_Auger"*}
       sed -i "s%G4P_PHYSICS_LIST%${phys}%" ${PWD}/tmp_run_${tool}.sh
    else
       sed -i "s%G4P_PHYSICS_LIST%${exp_physics}%" ${PWD}/tmp_run_${tool}.sh
    fi
    sed -i "s%G4P_INPUT_FILE%${exp_inp}%"       ${PWD}/tmp_run_${tool}.sh
    sed -i "s%G4P_OUTPUT_DIR%${work_dir}%"      ${PWD}/tmp_run_${tool}.sh
    sed -i "s%G4P_SPOOL_DIR%${spool_dir}%"      ${PWD}/tmp_run_${tool}.sh

#run all samples with EXTENDED PERFORMANCE (i.e., count tracks/steps) Jan-2016
    sed -i "s%G4P_PERFORMANCE_FLAG%EXTENDED%" ${PWD}/tmp_run_${tool}.sh
    
    #configuration
    sed    "s%G4P_PARTICLE_TYPE%${exp_procpid}%"  ${cfg_dir}/${exp_cfg} > ${PWD}/tmp_${exp_cfg} # ${sps_cfg}
    sed -i "s%G4P_GENERATOR_TYPE%${exp_gentype}%" ${PWD}/tmp_${exp_cfg} # ${sps_cfg}
    if [[ ${exp_energy} == *"MeV"* ]]; then
       sed -i "s%G4P_BEAM_ENERGY GeV%${exp_energy}%" ${PWD}/tmp_${exp_cfg}  # ${sps_cfg}
    else
       sed -i "s%G4P_BEAM_ENERGY%${exp_energy}%"     ${PWD}/tmp_${exp_cfg}  # ${sps_cfg}
    fi
    sed -i "s%G4P_SET_BFIELD%${exp_bfield}%"      ${PWD}/tmp_${exp_cfg}  # ${sps_cfg}
    if [[ ${exp_physics} == *"_Auger"*  ]]; then
       sed -i "s%#\/process\/em\/deexcitationIgnoreCut FLAG%\/process\/em\/deexcitationIgnoreCut true%" ${PWD}/tmp_${exp_cfg}  # ${sps_cfg}
       if [[ ${exp_physics} == *"_AugerOff"*  ]]; then
          sed -i "s%#\/process\/em\/auger FLAG%\/process\/em\/auger false%" ${PWD}/tmp_${exp_cfg}  # ${sps_cfg}
       fi
       if [[ ${exp_physics} == *"_AugerOn"*  ]]; then
          sed -i "s%#\/process\/em\/auger FLAG%\/process\/em\/auger true%"  ${PWD}/tmp_${exp_cfg}  # ${sps_cfg}
       fi
    fi
    
    #configuration-special treatment for optical photon 
    if [ x"${exp_procpid:0:8}" = x"optical+" ]; then
      # scale number of events and turn on the switch for stacking photons
      sed -i "s/optical+/ /"  ${sps_cfg}
      sed -i "s/setStackPhotons false/setStackPhotons true/" ${PWD}/tmp_${exp_cfg}  # ${sps_cfg}
      sed -i "s/G4P_NUMBER_BEAMON/26/" ${PWD}/tmp_${exp_cfg}  # ${sps_cfg}
    fi

    # change number of events for igprof
    if [ x"${tool}" = x"igprof" ]; then
      sed -i "s%G4P_NUMBER_BEAMON%${exp_igntot}%"   ${PWD}/tmp_${exp_cfg}  # ${sps_cfg}
    else
      sed -i "s%G4P_NUMBER_BEAMON%${exp_nevent}%"   ${PWD}/tmp_${exp_cfg}  # ${sps_cfg}
    fi

    #substitute parameters of template (template.run_igprof)
    sed -i "s%G4P_SAMPLE%${sample}%"      ${PWD}/tmp_run_${tool}.sh  # ${tool_sh}
    sed -i "s%G4P_IGPROF_NEVENT%${exp_igntot}%"  ${PWD}/tmp_run_${tool}.sh  # ${tool_sh}

    mv ${PWD}/tmp_submit_${tool} ${submit_jdl} 
    mv ${PWD}/tmp_master_${tool}.sh ${tool_master}
    mv ${PWD}/tmp_run_${tool}.sh ${tool_sh}
    mv ${PWD}/tmp_${exp_cfg} ${sps_cfg}

    # change permission to run scripts
    chmod +x ${work_dir}/*.sh
    
    #create link for input data file
    if [ x"${APPLICATION_NAME}" = x"SimplifiedCalo" -o \
         x"${APPLICATION_NAME}" = x"SimplifiedCaloMT" ]; then

      ln -s ${g4p_dir}/${APPLICATION_NAME}/SimplifiedCalo.gdml \
            ${work_dir}/SimplifiedCalo.gdml

      if [ x"${exp_sample}" = x"e-100MeV" ]; then
        ln -s ${INPUT_DIR}/e-100MeV_event.data ${work_dir}/hepevt.data
      else 
        ln -s ${INPUT_DIR}/pythia_event.data ${work_dir}/hepevt.data
      fi
    fi

    #create link for input data file
# --->    if [ x"${APPLICATION_NAME}" = x"cmsExp" -o \
# --->         x"${APPLICATION_NAME}" = x"cmsExpMT" ]; then
    if [[ ${APPLICATION_NAME} =~ "cmsExp" ]]; then
      ln -s ${g4p_dir}/${APPLICATION_NAME}/cmsExp.gdml \
            ${work_dir}/cmsExp.gdml
      ln -s ${g4p_dir}/${APPLICATION_NAME}/cmsExp.mag.3_8T \
            ${work_dir}/cmsExp.mag.3_8T

      if [ x"${exp_sample}" = x"e-100MeV" ]; then
        ln -s ${INPUT_DIR}/e-100MeV_event.data ${work_dir}/hepevt.data
      else 
        ln -s ${INPUT_DIR}/pythia_event.data ${work_dir}/hepevt.data
      fi
    fi

    #create link for lArTest gdml - use lArBox.gdml for initial tests
    #if [ x"${APPLICATION_NAME}" = x"lArTest" ]; then
    #  ln -s ${tar_dir}/${APPLICATION_NAME}/lArBox.gdml \
    #        ${work_dir}/lArTest.gdml
    #fi
  done

  # create files to submit pbs/slurm jobs (on the wilson)
  if [ -f ${cfg_dir}/template.wcic_submit_${tool} ]; then
    sed "s%G4P_EXP_DIR%${exp_dir}%" ${cfg_dir}/template.wcic_submit_${tool} >\
        ${exp_dir}/submit_all_${tool}.sh
    if [ x"${tool}" = x"igprof" ]; then
      if [[ ${APPLICATION_NAME} =~ "VG" ]]; then
        sed -i "s%g4.G4P_VERSION%g4vg.${GEANT4_RELEASE}%" ${exp_dir}/submit_all_${tool}.sh
      else
        sed -i "s%g4.G4P_VERSION%g4.${GEANT4_RELEASE}%" ${exp_dir}/submit_all_${tool}.sh
      fi
      sed -i "s%G4P_TARBALL_NAME%${tar_name}%" ${exp_dir}/submit_all_${tool}.sh
    fi
  else
    echo "Warning ${cfg_dir}/template.wcic_submit_${tool} does not exist!"
  fi
done

# create additional submit/run/analysis scripts for igprof
#
sed "s%G4P_EXP_DIR%${exp_dir}%" ${cfg_dir}/template.wcic_run_igprof_batch > tmp_run_igprof_batch.sh
chmod +x tmp_run_igprof_batch.sh
mv tmp_run_igprof_batch.sh ${exp_dir}/run_igprof_batch.sh
sed "s%G4P_EXP_DIR%${exp_dir}%" ${cfg_dir}/template.wcic_submit_igprof_to_batch > tmp_submit_igprof_to_batch.sh
chmod +x tmp_submit_igprof_to_batch.sh
mv tmp_submit_igprof_to_batch.sh ${exp_dir}/submit_igprof_to_batch.sh
sed "s%G4P_EXP_DIR%${exp_dir}%" ${cfg_dir}/template.wcic_analyze_all_igprof > tmp_analyze_all_igprof.sh
# --> no need --> chmod +x tmp_analyze_all_igprof.sh
mv tmp_analyze_all_igprof.sh ${exp_dir}/analyze_all_igprof.sh

# echo "changing permission for ${BLUEARC_DIR}/pbs "
# --> chmod -R g+w ${BLUEARC_DIR}/pbs

echo "changing permission for ${exp_dir} "
chmod -R g+w ${exp_dir}

