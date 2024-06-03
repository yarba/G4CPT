#!/bin/sh

PATH=${PATH}:/usr/bin
export PATH

Script=/work1/g4p/g4p/G4CPT/run_analysis.sh

# sbatch -N 1 -n 1 -c 1 -p wc_cpu --nodelist=wcwn090 --exclusive --qos=regular --time=16:00:00 --reservation=g4p_pct_interactive -A g4p $Script ${1} ${2} ${3} ${4}
# sbatch -N 1 -n 1 -c 1 -p wc_cpu --exclusive --qos=regular --reservation=g4p_pct_batch  -A g4p $Script ${1} ${2} ${3} ${4}
sbatch -N 1 -n 1 -c 1 -p wc_cpu --exclusive --qos=regular --reservation=g4p_pct_interactive  -A g4p $Script ${1} ${2} ${3} ${4}
# sbatch -N 1 -n 1 -c 1 -p wc_cpu --exclusive --qos=regular   -A g4p $Script ${1} ${2} ${3} ${4}



