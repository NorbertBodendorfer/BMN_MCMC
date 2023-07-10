#!/bin/bash
source functions_BSS_therm.sh

# Content: Batch submission script for BMN/BFSS matrix model to run on Athene in Regensburg. 

# Author: Norbert Bodendorfer, development version, use at your own risk.

# Based in part on a script written by Andreas Rabenstein for similar jobs submissions.



user=$(whoami)
#user="bon39708" # set user manually to overwrite whoami


############################################################################
################## ADJUSTMENT PARAMETERS HERE ##############################
############################################################################

# Compiletime parameters to select executable
nblock=2       # Split N into nblock blocks
nmat_block=2
nsublat=3      # Split lattice into nsublat sublattices
nsite_local=8

# Number of scalars, used only for bosonic runs
ndim=9

# Fluxes to loop over
flux_list="0"
#flux_list="2.0 3.0 4.0 5.0"

# Temperatures to loop over. Taken from temp_file if not overridden here
temp_file="../Temperatures_Prod_Intensive.txt"
#temp_file="../Temperatures_Prod.txt"

override_tempfile=1
#temp_list="1.1865 1.187 1.1875 1.188 1.1885 1.189 1.1895 1.19 1.1905 1.191 1.1915 1.192 1.1925"
temp_list="0.885"
#temp_list="0.526 0.527 0.528 0.529"
#temp_list="0.13 0.14 0.15 0.16"
#temp_list="0.746 0.748 0.75 0.3752 0.754"
#temp_list="0.24 0.246 0.248 0.25 0.255 0.26 0.27 0.28"
#temp_list="1.174 1.172 1.17"


# New config
oldconfig=0    # 0 for new config, otherwise n for latest config
fork_list="1"  # or "1 2 3 4 5".  Forking number nfork later read from list and looped over
nrun=$(( $oldconfig + 1 )) 
#nrun=2 # Maybe necessary to overwrite nrun in certain situations

# Runtime for job requested by qsub. Buffer subtracted later from this. 
time=$(( 1800 * 1 * 1 ))

# Often adjusted runtime parameters
nbc=1    # 0 -> pbc, 1 -> apbc
nbmn=0   # 0 -> BFSS, 1 -> BMN
ngauge=0 # 0 -> gauged, 1-> ungauged
init=1   # 0 -> old config, 1 -> new config, 2 -> fuzzy sphere
ntraj=1000000   # total number of sweeps
Ntau=5    # Sets initial Ntau, changed later for Production. 
Dtau_xmat_ref="0.01" # Dtau for xmat
Dtau_alpha_ref="0.014" # Dtau for alpha
purebosonic=1    # Disables all fermion routines, much faster


# Usually unchanged compile time parameters, some needed to determine the executable
nimprove=1
nremez_md=15
nremez_pf=15


# Usually unchanged runtime parameters
nskip=1    #
nsave=5000   #
iaccelerate=1  # 0 -> read from acc_input, 1-> naive
isave=0    # 0 -> save intermediate config, 1-> do not save
nsmear=0 # number of smearing.
s_smear="0.0d0" #
upper_approx=10000    # the largest eigenvalue of (M^dagger M)must be smaller than this.
max_err="1d-10"     # stopping condition for CG solver
max_iteration=100000    # maximum number of CG-iteration
g_alpha="1000d0"    # coefficient for constraint term of alpha
g_R="0d0"    # coefficient for constraint term of R
RCUT="100.0d0"    # cutoff for TrX^2
neig_max=0    # neig_max>0 -> calculate the largest eig of (D^dag*D).
neig_min=0    # !neig_min; neig_min>0 -> calculate the smallest eig of (D^dag*D).
nfuzzy=1    # number of fuzzy spheres. Used only when init=2.
mersenne_seed=4357   # seed for mersenne twistor, when init is not zero. Is overridden later by a random number, unless fixed_seed=1 is set below
fixed_seed=0
imetropolis=0    # 1 -> no Metropolis test (For thermalization)


# Usually unchanged options about naming the output / input files and directories
save_pref="/beegfs/${user}/BMN"       # "/beegfs/${user}/new/${action}"
executable_folder="executables"
executable_path="../${executable_folder}"
run_type_bmn="therm_broad"      # For historical reasons, output files for BMN and BFSS are stored in different folders 
run_type_bfss="BFSS_therm"

file_addition_input=""  # Pastes these affixes before .txt and .dat for input and output files, as well as before .pbs, e.g. for testruns
file_addition_output=""


memory_file="../memory_requirements.txt"



############################################################################
################## END OF ADJUSTMENT AREA ##################################
############################################################################


### Define some colors for errors / warnings

RED='\033[0;31m'
ORA='\033[0;35m'
NC='\033[0m' # No Color



### Determine derived parameters

# Derived file locations
if [ $nbmn -eq 0 ]
then
	run_type=$run_type_bfss
else
	run_type=$run_type_bmn
fi
datfile_folder="${run_type}_datfiles"
datfile_path="../${datfile_folder}"

pbs_folder="${run_type}_runs"

output_folder="${run_type}_output"




# Lattice size, number of cores and nodes
nL=$(( $nsublat * $nsite_local ))
nN=$(( $nmat_block * $nblock ))
nCores=$(( $nsublat * $nblock * $nblock ))
nNodes=$(( ($nCores+23) / 24 ))



# Determine gauged / ungauged prefix
if [ $ngauge -eq 0 ]
then
	if [ $purebosonic -eq 0 ]
	then
		gprefix="G"
	elif [ $purebosonic -eq 1 ]
	then
		gprefix="GB"
	else
		printf "${RED}Error, purebosonic set incorrectly to %d${NC}" $purebosonic 
	        exit	
	fi
elif [ $ngauge -eq 1 ]
then
	if [ $purebosonic -eq 0 ]
	then
		gprefix="U"
	elif [ $purebosonic -eq 1 ]
	then
		gprefix="UB"
	else
		printf "${RED}Error, purebosonic set incorrectly to %d${NC}" $purebosonic
	        exit	
	fi
else	
	printf "${RED}Error, ngauge set incorrectly to %d${NC}" $ngauge 
	exit	
fi





arg1="$1" #arg1 = "overwrite" disables the checking for already existing .pbs and .dat files during creation




##### START OF PROGRAM OUTPUT


echo
echo "---------------------------------------------------------------------------------------------"
echo "Batch creation of thermalization submission files for BFSS/BMN code by Masanori Hanada et al."
echo "---------------------------------------------------------------------------------------------"
#echo "v0.1: Fixed static paramters"
#echo "v0.2: Rearrangement of functions, cleanup, and bosonic option with new code"
echo 

echo "--------------"
echo "Preliminaries:"
echo "--------------"
echo

echo "User is" $user
echo


echo "Static run parameters:"
echo "L =" $nL "=" $nsublat "*" $nsite_local
echo "N =" $nN "=" $nblock "*" $nmat_block



# Determine queue
if [ $(( $nsublat * $nblock * $nblock )) -gt 24 ]
then
	queue="common"
else
	queue="serial"
fi
echo "Queue:" $queue "with" $(( $nsublat * $nblock * $nblock )) "total cores on" $nNodes "node(s)"
echo


if [ $(( $nCores )) -gt 24 ]
then
if [ $(( $nCores  )) -gt 0 ]
then
echo "Attention:" $(( $nCores %24 )) "cores =" $( echo "scale=0; -100*($nCores -$nNodes * 24 )  / ($nNodes * 24)"  | bc -l) "% wasted."
else
echo "No Cores wasted due to full node requirement."
fi
echo
fi


printf "PBS     folder: %s\n" $pbs_folder
printf "Output  folder: %s\n" $output_folder
printf "Datfile folder: %s\n" $datfile_folder

echo
# In this version of the script, walltime is the same for all flux/temperature/fork combinations. Does not need to be called in the loop
calculate_time
printf "Walltime: %s\n\n" $time


if [ $purebosonic -eq 0 ] 
then
	if [ $ndim = 9 ] 
	then
		:
	else
		printf "${RED}Error, purebosonic=0 contradicts ndim=%d. Needs to be ndim=9 or purebosonic=1.${NC}\n\n" $ndim
		exit
	fi
fi




### Initialize error counts of non-critical errors 

ec_no_exe=0
ec_overwrite_dat=0
ec_overwrite_pbs=0
ec_other=0


### Check whether init is set in correct way

if [[ init = 0 && nrun = 1 ]]; then
	printf "${ORA}WARNING: init is zero but nrun = 1. ${NC}\n"
	ec_other = $(( ec_other + 1 ))
fi


### Save qstat output to check if job is already running.
qstat > qstat_temp.txt 


echo "-------------------------------------------"
echo "Main loop over fluxes, temperatures, forks:"
echo "-------------------------------------------"
echo
echo

### Change directory to the pbs file directory

cd $pbs_folder

for nfork in $fork_list
do 

	for flux in $flux_list
	do
	    if [ $override_tempfile -eq 0 ]
	    then
		read_temperatures 
	    else
		printf "temp_list manually overwritten to: %s\n\n\n" $temp_list 
	    fi
 	    for temp in $temp_list
 	    do
		printf "M=%s, T=%s\n" $flux $temp    
		if [ $fixed_seed -eq 0 ] 
		then
			mersenne_seed=$( echo $RANDOM )   
	        fi
	        generate_jobname
		if grep -q "${jobname_wo_run}" "../qstat_temp.txt"
		then
            		printf "\t${RED}Job of type %s... still running. Terminating\n\n${NC}" $system
			exit
		else	
			calculate_dtaus
	        	calculate_memory
	        	create_pbs_file
	        	create_input_file
	        	echo ""
		fi
	    done
	done
done

cd ..



#### RUN SUMMARY


echo "--------"
echo "Summary:"
echo "--------"
echo

# Throw errors, e.g. executables did not exist etc
# Files overridden etc. 

ec_total=$(( ec_no_exe + ec_overwrite_dat + ec_overwrite_pbs + ec_other ))
if [ $ec_total -eq 0 ] 
then
	printf "No warnings encounterd. Script finished normally. \n" 
else
	printf "${ORA}WARNINGS ENCOUNTERED:\n\n${NC}" 
	printf "\t%d executables missing.\n" $ec_no_exe 
	printf "\t%d .pbs files overwritten.\n" $ec_overwrite_pbs 
	printf "\t%d .dat files overwritten.\n" $ec_overwrite_dat 
	printf "\t%d Other warnings.\n" $ec_other 
fi

echo
echo

exit


