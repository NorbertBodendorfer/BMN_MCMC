

function generate_jobname {
	jobname="${gprefix}_L${nL}N${nN}T${temp}M${flux}D${ndim}_F${nfork}_${nrun}${file_addition_output}"
	jobname_wo_run="th_${gprefix}_L${nL}N${nN}T${temp}M${flux}D${ndim}_F${nfork}_"
}



function read_ntau_dtau {
	if [ $set_ntau_temp -eq 1 ]
	then
		searchfile="../IP_Files/IP_${gprefix}N${nN}S${nL}D${ndim}.txt"
		searchstring="N${nN}S${nL}T${temp_ntau}M${flux}"
	else
		searchfile="../IP_Files/IP_${gprefix}N${nN}S${nL}D${ndim}.txt"
		searchstring="N${nN}S${nL}T${temp}M${flux}"
	fi
	if grep -q "${searchstring}" "${searchfile}"
	then 
		Ntau=$( grep "${searchstring}" "${searchfile}" | tr -s ' ' |  cut -f5 -d' ' | head -1 )
		Dtau_xmat=$( grep "${searchstring}" "${searchfile}" | tr -s ' ' | cut -f6 -d' ' | head -1 )
		Dtau_alpha=$(echo "scale=6; ${Dtau_xmat} * 1.4" | bc | awk '{printf "%f", $0}')
	else
            printf "\t${RED}No ntau specified for %s in  %s. Terminating\n\n${NC}" $searchstring $searchfile
	    exit
	fi
}


function calculate_prev_traj {
	outfile_pattern="${save_pref}/${run_type}_output/out${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_*"
	prev_traj=0
	run_num=1
	oldconfig=1 # initialize old config to 1
	shopt -s nullglob # no looping over empty file lists

	for filename in $outfile_pattern; do
		    add_traj=$( cat $filename | wc -l )
		    prev_traj=$( echo "$prev_traj + $add_traj - 32" | bc  ) 
		    oldconfig=$(( $run_num )) # In case there is more than one trajectory recorded, set old_config to the the value of previous files
		    #echo $old_config
		    run_num=$(( run_num + 1 ))
		    # Should now work for different fork levels. Probably also not really necessary right now due to many parallel jobs
	done
}



function calculate_time {
    if [ $nNodes -gt 1 ] 
    then
   	 time_cap=$(( time - 1800 ))  ## Larger buffer to prevent loss of confiles due to too long writing process
    else
   	 time_cap=$(( time - 600 ))
    fi

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
            echo "ERROR: walltime of $hour hours exceeds the limit of 168 hours".
	    exit
        fi
    if [ $(echo $hour | wc -c ) -lt 3 ]
    then
        hour="0${hour}"
    fi
    time=$(echo "${hour}:${min}:00")
}




function read_temperatures {
	searchstring="${gprefix}N${nN}S${nL}M${flux}D${ndim}"
	temp_list=$( grep "${searchstring}" "${temp_file}" | tr -s ' ' | cut -d' ' -f2-   )
}




function read_con_file_from_therm {
    	if [ $hyst -eq 1 ]
	then
		searchstring_con="${save_pref}/${therm_dir}/con${gprefix}N${nN}S${nL}T${temp_hysteresis}M${flux}D${ndim}_F${nfork}_*"
		searchstring_icon="${save_pref}/${therm_dir}/icon${gprefix}N${nN}S${nL}T${temp_hysteresis}M${flux}D${ndim}_F${nfork}_*"
	else
		searchstring_con="${save_pref}/${therm_dir}/con${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_*"
		searchstring_icon="${save_pref}/${therm_dir}/icon${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_*"
	fi

	con_path="NOCONFILE"
	icon_path="NOICONFILE"
	#confile_found=0
#	echo "Searchstring_con: $searchstring_con"
#	echo "$searchstring_con"
	#if [ -f "${searchstring_con}" ] 
	#then
	#	con_path=$(  ls -t $searchstring_con | head -1 ) # Get newest configuration file with those temperatures and fluxes
	#	confile_found=1
	#	echo "file exists"
	#elif [ -f "$searchstring_icon" ] 
	#then
	#	icon_path=$(  ls -t $searchstring_icon | head -1 ) # Get newest configuration file with those temperatures and fluxes
	#	confile_found=1
	#	echo "No configuration file found, intermediate configuration found. Using this."
	#fi
	#echo $con_path

	#if [ $confile_found -eq 0 ]
	#then
	#	echo "No configuration file matching $searchstring_con or $searchstring_icon found. Terminating."
	#	exit
	#fi

## Probably the middle of this function is not necessary. last two lines + top is enough
	

	## THIS ls version to get the latest file doesn't work properly if there are no files, it gives the PBS file. The code below works now. 
	#con_path=$( ls -t $searchstring_con | head -1 )


	shopt -s nullglob
	unset -v latest
	#for file in "${save_pref}/${therm_dir}/con${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_*"; do
	for file in $searchstring_con; do
		[[ $file -nt $latest ]] && latest=$file
	done
	con_path=$latest


	#icon_path=$( ls -t $searchstring_icon | head -1 )
	
	
	unset -v latest
	#for file in "${save_pref}/${therm_dir}/icon${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_*"; do
	for file in $searchstring_icon; do
		[[ $file -nt $latest ]] && latest=$file
	done
	icon_path=$latest
	
	
	
#	echo "con path after function: " $con_path
}




function calculate_memory {
	if [ $purebosonic -eq 1 ] 
	then
		system="${gprefix}N${nN}S${nL}D${ndim}C${nCores}"
	else
		system="${gprefix}N${nN}S${nL}C${nCores}"
	fi
	
	memory="${gprefix}N${nN}S${nL}M${flux}D${ndim}"

	if grep -q "${system}" "${memory_file}"
	then 
		memory=$( grep "${system}" "${memory_file}" | tr -s ' ' | cut -d' ' -f2-   )
	else
            printf "\t${RED}No memory specified for  %s. Terminating\n\n${NC}" $system
	    exit
	fi
        memory="${memory}m"
}




function create_pbs_file {

    outfile=${jobname}.pbs
	
    ow=0

    outfile_with_path="${pbs_folder}/${outfile}"
    
    #File existence check
    if [ -f $outfile ]; then
        if [ "$arg1" = "overwrite" ]; then
            printf "\t${ORA}Overwriting %s\n${NC}" $outfile_with_path
	    ec_overwrite_pbs=$(( ec_overwrite_pbs + 1 )) # add to error count
            rm $outfile
	    ow=1
        else
            printf "\t${RED}File %s already exists. Terminating\n${NC}" $outfile
            exit
        fi
    fi
    
    if [ $ow -eq 0 ] 
    then
	    printf "\tWriting %s" $outfile_with_path
    fi

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
	executable="BMN_I_D_${ndim}_L_${nsublat}_${nsite_local}_N_${nblock}_${nmat_block}_M_Tmpi_bosonic_georg_con"
    	if [ $srng -eq 1 ]
	then
		executable="${executable}_srng"	
	fi
	exe_path_file="../${executable_folder}/${executable}"	
	echo "mpiexec -n ${nCores} ${exe_path_file} ${datfile_path}/${jobname}.dat ${time_cap}d0" >> $outfile
	



	## Check if executable exists
	if [ -f $exe_path_file ]
       	then
		:
	else
		printf "${ORA}\n\tAttention: executable %s does not exist.\n${NC}" $exe_path_file
		ec_no_exe=$(( ec_no_exe + 1 ))
	fi

}




function create_input_file {

    outfile="${datfile_path}/${jobname}.dat"

    ow=0 #outfile will be overwritten if ow=1

    outfile_with_path="${run_type}_datfiles/${jobname}.dat"
    
    #File existence check
    if [ -f $outfile ]; then
        if [ "$arg1" = "overwrite" ]; then
            printf "\t${ORA}Overwriting %s\n${NC}" $outfile_with_path
	    ec_overwrite_dat=$(( ec_overwrite_dat + 1 )) # add to error count
            rm $outfile
	    ow=1
        else
            printf "\t${RED}File %s already exists. Terminating\n${NC}" $outfile
            exit
        fi
    else
        echo "" #File $outfile does not exist."
    fi

    if [ $ow -eq 0 ] 
    then
 	 printf "\tWriting %s\n" $outfile_with_path
    fi

    #Write input file
    #echo "'${save_pref}/output/conN${nN}S${nL}T${temp}M${flux}_F${nfork}_${oldconfig}.dat'    !input_config" >> $outfile
    #echo "'$confile'    ! MODIIED FOR 24/16 input_config" >> $outfile

    if [ $run_num -eq 1 ] 
    then
	read_con_file_from_therm
    else
   	con_path="${save_pref}/${output_folder}/con${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_${oldconfig}${file_addition_input}.dat"
   	icon_path="${save_pref}/${output_folder}/icon${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_${oldconfig}${file_addition_input}.dat"
    fi
    
    # Make some checks on configuration files and use intermediate configuraiton if necessary / possible. 
    confile_check=0
    if [[ init -eq 1 ]]; then
	    confile_check=1
    fi
    if [[ ! -f $con_path ]]; then
	printf "${ORA}\tWARNING: configuration file %s does not exist.\n${NC}" $con_path
    else
	confile_check=1
    fi

    if [[ ! -f $icon_path ]]; then
	printf "${ORA}\tWARNING: Intermedate configuration %s does not exist.\n${NC}" $icon_path
    else
	if [[ confile_check -eq 0 ]]; then
		con_path=$icon_path
		printf "${ORA}Intermedate configuration %s exists. Using this instead.${NC}\n" $icon_path
		confile_check=1
	fi
    fi

    if [[ confile_check -eq 0 ]]; then
	    printf "${RED}No (intermediate) configuration with same fork/run found and init not 1. Terminating.${NC}\n"
	    exit
    fi 
    

   #	 if [[ ! -f $con_path ]]; then
#		 echo "in second if"
#		printf "${ORA}\tWARNING: configuration file  %s does not exist.\n${NC}" $con_path
 #  	 echo "iconpath in second if" $icon_path	
#		if [ -f $icon_path ]; then
#			printf "${ORA}Intermedate configuration %s exists. Using this instead.${NC}\n" $icon_path
#			echo "using intermedaite configuratino"
#			con_path=$icon_path
#		else
#			printf "${RED}No intermediate configuration with same fork/run found. Terminating.${NC}\n"
#			exit
#		fi
#	 fi


    echo "'${con_path}'    !input_config" >> $outfile
    echo "'${save_pref}/${output_folder}/con${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_${nrun}${file_addition_output}.dat'    !output_config" >> $outfile
    echo "'${save_pref}/${output_folder}/out${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_${nrun}${file_addition_output}.txt'    !data_output" >> $outfile
    echo "'${save_pref}/${output_folder}/phase${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_${nrun}${file_addition_output}.txt'    !phase_output" >> $outfile
    echo "'${save_pref}/${output_folder}/icon${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_${nrun}${file_addition_output}.dat'      !intermediate_config" >> $outfile
    echo "'${save_pref}/${output_folder}/acc_${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_${oldconfig}${file_addition_output}.dat'      !acc_input" >> $outfile
    echo "'${save_pref}/${output_folder}/acc_${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_${nrun}${file_addition_output}.dat'      !acc_output" >> $outfile
    echo "'${save_pref}/${output_folder}/CG_${gprefix}N${nN}S${nL}T${temp}M${flux}D${ndim}_F${nfork}_${nrun}${file_addition_output}.dat'       !CG_log" >> $outfile
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
    echo "${purebosonic}    !purebosonic; 0 -> full theory, 1 -> only bosonic part" >> $outfile
    echo "${myersfix}d0       ! myersfix; value for fixing the myers term" >> $outfile
    echo "${g_myers}        ! g_myers; supression level of fluctuations" >> $outfile
    echo "${myers_fix_width}d0     ! myers_fix_width width of unconstraint fluctuations" >> $outfile
    echo "${polfix}d0      ! polfix same for the Polyakov loop fixing" >> $outfile
    echo "${g_pol}      ! g_pol" >> $outfile
    echo "${pol_fix_width}d0     ! pol_fix_width" >> $outfile



   }




