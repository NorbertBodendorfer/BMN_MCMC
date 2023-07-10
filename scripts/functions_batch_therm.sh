
## calculate_time -> time=$(estimated WC time in hours)
## calculate_memory -> memory=$(estimated memory in mb)
## round_beta -> rounds beta to 15 digits
## generate_jobname -> jobname=$("jobname")
## find_step -> finds step where to start
## generate_pbs_script -> generates .pbs script
## check_initial_data -> for step > 0; checks if all configs and rnd files exist
## generate_save_name -> generates filename of saved config and rnd file
## check_number_of_jobs -> checks how much jobs are in the queue and sleeps


function generate_jobname {
local length=${1:-33}
jobname="th_${gprefix}_L${nL}N${nN}T${temp}M${flux}_F${nfork}_${nrun}"
#echo $jobname
# Can be added later

#if [ $(echo $jobname | wc -c) -gt $length ]
#then
#local length2=$(($length -3))
#local reduce=$(( $(echo $jobname | wc -c) - $length2 ))
#local beta_length=$(( $(echo $beta | wc -c) - 1))
#local betaLoc=$(printf "%.$((${beta_length}-${reduce}))f" ${beta})
#jobname="S${SUN}T${T}L${L}l${l}g${g}a${alpha}b${betaLoc}s${step}n${node}"
#fi
}


function calculate_dtaus {
	if [ $nrun -eq 1 ]
	then
	 	Dtau_xmat=$Dtau_xmat_ref
		Dtau_alpha=$Dtau_alpha_ref 
	else # Read last ntau value
	infile="${save_pref}/therm_broad_output/ntau${gprefix}N${nN}S${nL}T${temp}M${flux}_F${nfork}_${oldconfig}.txt"

	echo $infile


	Ntau=$( tail -1 $infile | tr -s ' ' | cut -d' ' -f3 )
	
	echo $Ntau

	# Increase Nau if old one was too low and resulted in low acceptance before stop of last thermalization
	#Ntau=$(( $Ntau + 10 ))
	#echo $Ntau
	
	#infile="../Intermediate_Temperatures_2.txt"
	#searchstring="${gprefix}N${nN}S${nL}M${flux}"
	#temp_list_add=$( grep "${searchstring}" "${infile}" | tr -s ' ' | cut -d' ' -f2-   )
	
	
	fi
	

	Dtau_xmat=$(printf '%.6f\n' "$(echo "scale=6; 0.1 / ${Ntau}" | bc)")
	Dtau_alpha=$(printf '%.6f\n' "$(echo "scale=6; 0.14 / ${Ntau}" | bc)")
}


function calculate_time {
#    if [ $step -eq 0 ]
#    then
#        time=$(( ${N_THERM}*${time_per_update}))
#    fi
    time=$(( 3600 * 24 * 1 ))
    time_cap=$(( time - 6000 ))
    #time=172800
    #time_cap="172200d0"

    local sec=$(echo "${time}%60" | bc)
    local min=$(echo "${time}/60" | bc)
    local min=$(echo "${min}%60" | bc)
    if [ $(echo $min | wc -c ) -lt 3 ]
    then
        min="0${min}"
    fi
        local hour=$(echo "${time}/60/60" | bc)
    if [ $hour -gt 191 ]
        then
            echo
            echo "Attention: walltime of $hour hours exceeds the limit of 168 hours".
            echo
        fi
    if [ $(echo $hour | wc -c ) -lt 3 ]
    then
        hour="0${hour}"
    fi
    time=$(echo "${hour}:${min}:00")
    echo "Walltime:" $time " with buffer" $security_factor 
}




function read_intermediate_temperatures {
	#infile="../Intermediate_Temperatures_2.txt"
	infile="../Temperatures_Prod.txt"
	searchstring="${gprefix}N${nN}S${nL}M${flux}"
	temp_list_add=$( grep "${searchstring}" "${infile}" | tr -s ' ' | cut -d' ' -f2-   )
	echo $temp_list_add
	temp_list=$temp_list_add
	#echo $temp_list
	#temp_list=$temp_list_basic
	#temp_list="0.1 0.12 0.14 0.16 0.18 0.22 0.24" # Interesting points for mu = 1.0
	#temp_list="0.1 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19" # Interesting points for mu = 0.5
	#temp_list="1.105 1.115 1.125 1.135 1.145 1.155 1.165 1.175 1.185 1.195 1.205 1.215 1.225 1.235"
 	temp_list="0.543"
 	#temp_list="0.73 0.75 0.77 0.79 0.81 0.82 0.83"
	#temp_list="1.183 1.185 1.187 1.189"  #Mu=5, N=32
	#temp_list="0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5"  #Mu=3, N=32
	#temp_list="0.752 0.754 0.756 0.758"  #Mu=3, N=32
	#temp_list="1.187 1.189" # Testtemperature for Mu=5
	#temp_list="12.0 14.0 16.0 18.0 20.0" # Trial temperature for transition for Mu=5
	#temp_list="0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29" #Mu=2, N=32
}


function read_con_file {
	
	searchstring="/beegfs/bon39708/BMN/therm_broad_output/con${gprefix}N${nN}S${nL}T${temp}M${flux}_*"
	confile=$(  ls -t $searchstring | head -1 )
	echo $confile
}





function calculate_memory {

	system="${gprefix}N${nN}S${nL}C${nCores}"


	case "$system" in
	GN48S12C288)
            	memory=125
            ;; 
	GN32S12C128)
            	memory=120
            ;; 
	GN48S24C432)
            	memory=200
            ;; 
	GN48S12C576)
            	memory=105
            ;; 
	GN48S12C192)
            	memory=200
            ;; 
	GN48S12C432)
            	memory=115
            ;; 
	GN32S12C192)
            	memory=100
            ;; 
	UN32S12C192)
            	memory=100
            ;; 
	GN32S24C192)
            	memory=120
            ;; 
	GN24S12C12)
            	memory=500
            ;; 
        GN24S24C12)
            	memory=500
            ;; 
 	GN8S24C12)
            	memory=100
            ;; 
 	GN8S4C8)
            	memory=150
            ;; 
 	GN8S48C24)
            	memory=200
            ;; 
 	GN8S96C24)
            	memory=400
            ;; 
 	GN8S192C24)
            	memory=800
            ;; 
        GN12S24C12)
            	memory=120
            ;; 
     	GN16S24C12)
            	memory=170
            ;; 
 	UN8S24C12)
            	memory=120
            ;; 
        UN12S24C12)
            	memory=140
            ;; 
     	UN16S24C12)
            	memory=190
            ;; 
 	UN8S48C12)
            	memory=120
            ;; 
        UN12S48C12)
            	memory=170
            ;; 
     	UN16S48C12)
            	memory=265
            ;; 
 	GN8S12C12)
            	memory=90
            ;; 
 	GN12S12C12)
            	memory=100
            ;; 
 	GN16S12C12)
            	memory=120
	    ;;
 	UN4S6C12)
            	memory=80
            ;; 
 	UN8S12C12)
            	memory=90
            ;; 
 	UN12S12C12)
            	memory=85
            ;; 
 	UN16S12C12)
            	memory=90
            ;; 
 	GN8S48C12)
            	memory=115
            ;; 
 	GN12S48C12)
            	memory=165
            ;; 
 	GN16S48C12)
            	memory=250
            ;; 
 	GN32S24C12)
            	memory=750
            ;; 
 	GN32S12C12)
            	memory=750
            ;; 
 	GN8S24C24)
		memory=130
	    ;;
        *)
            echo "No memory size specified for system " $system
            exit 1
esac
memory="${memory}m"
}




function create_pbs_file {

    #outfile=${script_dir}/${jobname}.pbs
    outfile=${jobname}.pbs

    #File existence check
    if [ -f $outfile ]; then
        if [ "$arg1" = "overwrite" ]; then
            echo "File $outfile already exists. Overwriting!"
            rm $outfile
        else
            echo "File $outfile already exists. Terminating"
            exit
        fi
    else
        echo "" #"File $outfile does not exist."
    fi
    
    echo "Writing" $outfile

    #Write pbs file
    echo "#!/bin/bash" >> $outfile
    echo "" >> $outfile
    echo "#PBS -l nodes=${nNodes}:ppn=$(($nCores<25?$nCores:24))" >> $outfile
    echo "#PBS -l walltime=${time}" >> $outfile
    echo "#PBS -q $queue" >> $outfile
    echo "#PBS -l pmem=${memory}" >> $outfile
    echo "#ATHOS -o iset=avx2" >> $outfile
    echo "#ATHOS -deps SELF-PROVIDED:BFSS-MMoL" >> $outfile
#    echo "#PBS -e /home/${user}/BMN/MP-ProductionRuns/output/" >> $outfile
#    echo "#PBS -o /home/${user}/BMN/MP-ProductionRuns/output/" >> $outfile
    echo "cd \"\$PBS_O_WORKDIR\"" >> $outfile
#echo "#ATHOS -deps ${deps}" >> $outfile
   echo  "" >> $outfile
#Later add here further specifications for improved, BFSS, etc.
    	echo "time mpiexec -n ${nCores} ../executables_new/BMN_I_L_${nsublat}_${nsite_local}_N_${nblock}_${nmat_block}_M_T_Th_ntau ../therm_broad_datfiles/${jobname}.dat ${time_cap}d0 ${save_pref}/therm_broad_output/ntau${gprefix}N${nN}S${nL}T${temp}M${flux}_F${nfork}_${nrun}.txt" >> $outfile
}


function create_input_file {

    #outfile=${script_dir}/${jobname}.dat
    if [ "$arg2" = "testrun" ] ; then
	    outfile="../testdatfiles/${jobname}.dat"
	else
	    outfile="../therm_broad_datfiles/${jobname}.dat"
    fi

    #File existence check
    if [ -f $outfile ]; then
        if [ "$arg1" = "overwrite" ]; then
            echo "File $outfile already exists. Overwriting!"
            rm $outfile
        else
            echo "File $outfile already exists. Terminating"
            exit
        fi
    else
        echo "" #File $outfile does not exist."
    fi

    echo "Writing" $outfile

    #Write input file
    #echo "'${save_pref}/output/conN${nN}S${nL}T${temp}M${flux}_F${nfork}_${oldconfig}.dat'    !input_config" >> $outfile
    #echo "'$confile'    ! MODIIED FOR 24/16 input_config" >> $outfile
    echo "'${save_pref}/therm_broad_output/con${gprefix}N${nN}S${nL}T${temp}M${flux}_F${nfork}_${oldconfig}.dat'    !input_config" >> $outfile
    echo "'${save_pref}/therm_broad_output/con${gprefix}N${nN}S${nL}T${temp}M${flux}_F${nfork}_${nrun}.dat'    !output_config" >> $outfile
    echo "'${save_pref}/therm_broad_output/out${gprefix}N${nN}S${nL}T${temp}M${flux}_F${nfork}_${nrun}.txt'    !data_output" >> $outfile
    echo "'${save_pref}/therm_broad_output/phase${gprefix}N${nN}S${nL}T${temp}M${flux}_F${nfork}_${nrun}.txt'    !phase_output" >> $outfile
    echo "'${save_pref}/therm_broad_output/icon${gprefix}N${nN}S${nL}T${temp}M${flux}_F${nfork}_${nrun}.dat'      !intermediate_config" >> $outfile
    echo "'${save_pref}/therm_broad_output/acc_${gprefix}N${nN}S${nL}T${temp}M${flux}_F${nfork}_${oldconfig}.dat'      !acc_input" >> $outfile
    echo "'${save_pref}/therm_broad_output/acc_${gprefix}N${nN}S${nL}T${temp}M${flux}_F${nfork}_${nrun}.dat'      !acc_output" >> $outfile
    echo "'${save_pref}/therm_broad_output/CG_${gprefix}N${nN}S${nL}T${temp}M${flux}_F${nfork}_${nrun}.dat'       !CG_log" >> $outfile
    echo "${nbc}    !nbc; 0 -> pbc, 1 -> apbc" >> $outfile
    echo "${nbmn}    !nbmn; 0 -> BFSS, 1 -> BMN" >> $outfile
    echo "${ngauge}    !ngauge; 0 -> gauged, 1-> ungauged" >> $outfile
    echo "${nsmear}    !nsmear; number of smearing." >> $outfile
    echo "${s_smear}    !s_smear" >> $outfile
    echo "${init}    !init; 0 -> old config, 1 -> new config, 2 -> fuzzy sphere" >> $outfile
    echo "${iaccelerate}    !iaccelerate; 0 -> read from acc_input, 1-> naive" >> $outfile
    echo "${isave}    !isave; 0 -> save intermediate config, 1-> do not save" >> $outfile
    echo "${temp}d0    !temperature" >> $outfile
    echo "${flux}d0    !flux parameter mu; used only when nbmn=1" >> $outfile
    echo "${ntraj}    !ntraj(total number of sweeps)" >> $outfile
    echo "${nskip}    !nskip" >> $outfile
    echo "${nsave}    !nsave" >> $outfile
    echo "${Ntau}    !Ntau" >> $outfile
    echo "${Dtau_xmat}d0    !Dtau for xmat" >> $outfile
    echo "${Dtau_alpha}d0    !Dtau for alpha" >> $outfile
    echo "${upper_approx}    !upper_approx; the largest eigenvalue of (M^dagger M)must be smaller than this." >> $outfile
    echo "${max_err}     !max_err; stopping condition for CG solver" >> $outfile
    echo "${max_iteration}    !max_iteration; maximum number of CG-iteration" >> $outfile
    echo "${g_alpha}    !g_alpha; coefficient for constraint term of alpha" >> $outfile
    echo "${g_R}    !g_R; coefficient for constraint term of R" >> $outfile
    echo "${RCUT}    !RCUT; cutoff for TrX^2" >> $outfile
    echo "${neig_max}    !neig_max; neig_max>0 -> calculate the largest eig of (D^dag*D)." >> $outfile
    echo "${neig_min}    !neig_min; neig_min>0 -> calculate the smallest eig of (D^dag*D)." >> $outfile
    echo "${nfuzzy}    !nfuzzy; number of fuzzy spheres. Used only when init=2." >> $outfile
    echo "${mersenne_seed}    !mersenne_seed; seed for mersenne twistor, when init is not zero." >> $outfile
    echo "${imetropolis}    !imetropolis; 1 -> no Metropolis test (For thermalization)" >> $outfile

}

function check_initial_data {
step=$(( $step -1 ))
local AllExists=true
for type in "config" "rnd"
do
for thread in $(seq 0 $((${cores}-1)) )
do
local name=$(generate_save_name $type)
if [ ! -e  ${save_pref}/${type}/${name}.bin ]
then
echo "${save_pref}/${type}/${name}.bin"

local glurchExists=$(check_glurch ${type}/${name}.bin)
if  ! $glurchExists
then
AlleExists=false
echo "$type $name (thread ${thread})for $jobname does not exist"
fi
fi
done
done
if ! $AllExists
then
exit
fi
step=$(( $step + 1 ))

}




function round_beta {
	if [ $(echo $beta | wc -c) -ge 15 ]
	then
		tmp=$(echo $beta | cut -d "." -f 1 | wc -c)
		tmp=$(( 15 - ${tmp} +1 ))
		beta=$(printf "%.${tmp}f" $beta)
	fi

}



function find_step {
	previous_job=""

	len=34
	for len in 30 31 32 33 34
	do
		step=".*"
		generate_jobname $len
		step=$(cat ${submittedFile} | grep "$jobname" | sed "s/\(.*\)b\(.*\)s\(.*\)n${node}.pbs/\3/" | sort -n | tail -1)
		if [ -z ${step} ]
		then
			step=0
		else
			
			generate_jobname 
			local N_MEAS_last=$(cat ${script_dir}/${jobname}.pbs | grep "$code" | sed -e "s|\(.*\)--N_MEAS \(.*\) --.*|\2|" | cut -d " " -f 1)
			step=$((${step} + ${N_MEAS_last}+1))
			### CHECK IF JOB IS RUNNING
			if [ ! -z "$(qstat | grep "$jobname")" ]
			then
				previous_job=$(qstat | grep "$jobname" | cut -d " " -f 1)
				isRunning=true
			fi
			return
		fi
	done
}

function generate_pbs_script {

	if [ $step -eq 0 ]
	then
		generate_random_file
		local add="--seed_file ${localRandomFile}"
	fi
	outfile=${script_dir}/${jobname}.pbs
	echo "#!/bin/bash" >> $outfile
	echo "" >> $outfile
	echo "#PBS -l nodes=1:ppn=${cores}" >> $outfile
	echo "#PBS -l walltime=${time}" >> $outfile
	echo "#PBS -q $queue" >> $outfile 
	echo "#PBS -l mem=${memory}" >> $outfile 
	echo "#PBS -e /home/${user}/output/" >> $outfile 
	echo "#PBS -o /home/${user}/output/" >> $outfile
	echo "#ATHOS -deps ${deps}" >> $outfile
	echo "#ATHOS -o iset=avx2" >> $outfile
	echo  "" >> $outfile
	echo "$code \
-T ${T} \
-L ${L} \
-l ${l} \
-g ${g} \
--beta ${beta} \
--alpha ${alpha} \
--u0 ${u0} \
--step ${step} \
--cores ${cores} \
--node ${node} \
--N_THERM ${N_THERM} \
--N_REUNIT ${N_REUNIT} \
--N_WAIT ${N_WAIT} \
--N_WRITE ${N_WRITE} \
--N_MEAS ${N_MEAS} \
--N_OVER ${N_OVER} \
--WC_TIME ${time} \
${add} \
" >> $outfile
	
}

function check_initial_data {
	step=$(( $step -1 ))
	local AllExists=true
	for type in "config" "rnd"
	do
		for thread in $(seq 0 $((${cores}-1)) )
		do
			local name=$(generate_save_name $type)
			if [ ! -e  ${save_pref}/${type}/${name}.bin ]	
			then	
				echo "${save_pref}/${type}/${name}.bin"
	
				local glurchExists=$(check_glurch ${type}/${name}.bin)
				if  ! $glurchExists
				then
					AlleExists=false
					echo "$type $name (thread ${thread})for $jobname does not exist"					
				fi
			fi
		done
	done
	if ! $AllExists
	then
		exit
	fi
	step=$(( $step + 1 ))
}

function check_glurch {
	local filename=$1
	if [ -e ${glurch_pref}/${filename} ]
	then
		rsync -a ${glurch_pref}/${filename} ${save_pref}/${filename}
		echo true
	else
		echo false
	fi
}

function generate_save_name {
	local type=$1
	echo "${type}_SU_N_${SUN}_T_${T}_L_${L}_l_${l}_g_${g}_alpha_${alpha}_beta_${beta}_u0_${u0}_step_${step}_node_${node}_thread_${thread}"
}

function check_number_of_jobs {
	local number=$(qstat | grep " serial " | wc -l)
	sleep 3s
	local numberAll=$(qstat -a | grep "serial" | wc -l)
#	while  ( [ $number -ge $number_of_jobs_in_queue ] || [ $numberAll -ge $number_of_all_jobs_in_queue ] )
#	do
#		echo "SLEEPING.. ($(date)) ${SimulationFile} ${number} ${numberAll} "
#		sleep ${sleep_time}
#		number=$(qstat | grep " ${user} " | wc -l)
#		sleep 3s
#		numberAll=$(qstat -a | grep "serial" | wc -l)
#		update_qparams
#	done
	while [ ! -z "$(qparams ${queue} | grep "qlimit already reached")" ]
	do
		echo "SLEEPING.. ($(date)) ${SimulationFile} ${number} ${numberAll} "
		sleep ${sleep_time}
		number=$(qstat | grep " ${user} " | wc -l)
		sleep 3s
		numberAll=$(qstat -a | grep "serial" | wc -l)
		
	done
}

function generate_random_file {
	localRandomFile="/home/${user}/EntanglementEntropy/start_scripts/random/random_S${SUN}_T${T}_L${L}_l${l}_a${alpha}_b${beta}_n${node}.txt"
	cat $randomFile | grep -v "USED" | head -${cores} > $localRandomFile
	if [ $(cat $localRandomFile | wc -l) -ne $cores ]
	then
		$codeRND
		if [ $(cat $randomFile | wc -l) -ne $(cat $randomFile | cut -d " " -f 1 | sort | uniq | wc -l) ]
		then
			echo "Double random numbers"
			numberUSED=$(cat $randomFile  | grep "USED" | wc -l)
			awk '!a[$1]++' $randomFile > random/tmp.txt

			numberUSED2=$(cat random/tmp.txt  | grep "USED" | wc -l)
			if [ $numberUSED -ne $numberUSED2 ]
			then
				echo "Removed USED name"
				#exit
			fi
			mv random/tmp.txt $randomFile
		
		fi
		cat $randomFile | grep -v "USED" | head -${cores} > $localRandomFile
	fi
	while read line 
	do
		sed -i "s|${line}|${line} USED|g" $randomFile
	done < $localRandomFile
}

function jobname_to_parameters {
	local jobname=$1
	SUN=$(echo $jobname | sed -e 's|S\(.*\)T.*|\1|')
	T=$(echo $jobname | sed -e 's|.*T\(.*\)L.*|\1|')
	L=$(echo $jobname | sed -e 's|.*L\(.*\)l.*|\1|')
	l=$(echo $jobname | sed -e 's|.*l\(.*\)g.*|\1|')
	g=$(echo $jobname | sed -e 's|.*g\(.*\)a.*|\1|')
	alpha=$(echo $jobname | sed -e 's|.*a\(.*\)b.*|\1|')
	beta=$(echo $jobname | sed -e 's|.*b\(.*\)s.*|\1|')
	step=$(echo $jobname | sed -e 's|.*s\(.*\)n.*|\1|')
	node=$(echo $jobname | sed -e 's|.*n\(.*\)|\1|')
}

function update_qparams {
#	number_of_jobs_in_queue=$(( $(qparams serial | grep max_user | cut -d "=" -f 2 | cut -d " " -f 2) - 5 ))
#	number_of_all_jobs_in_queue=$(( $( qparams serial | grep max_queuable | cut -d "=" -f 2 | cut -d " " -f 2) -5 ))
	number_of_jobs_in_queue=250
	number_of_all_jobs_in_queue=2000
}

function get_options {
	while getopts "f:s:-:" option
	do
		case "${option}"
		in
			f)
				SimulationFile=${OPTARG}
			;;
			s)
				stepMaxSimulate=${OPTARG}
			;;
			-)
				LONG_ARG=${OPTARG#*=}
				case ${OPTARG} in
					SimulationFile=?* )
						SimulationFile=${LONG_ARG}
					;;
					stepMaxSimulate=?* )
						stepMaxSimulate=${LONG_ARG}
					;;
				esac
			;;
			*)
				echo "${option} not know"
				exit
			;;
		esac
	done
}	
