universe = grid
GridResource = gt2 fnpcosg1.fnal.gov/jobmanager-condor
executable = prof.sh 
arguments = $(Cluster) $(Process) $ENV(USER) $ENV(PWD) /mu2e/data/outstage
output =  grid01.$(Cluster).$(Process).out
error =   grid01.$(Cluster).$(Process).err
log =     grid01.$(Cluster).$(Process).log
transfer_input_files = 
when_to_transfer_output = ON_EXIT
notification = NEVER
queue 100
