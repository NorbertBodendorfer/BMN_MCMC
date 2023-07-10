#!/bin/bash


while true
do 

	printf "\n\nStarting new iteration of autosubmission script on "
	date
	printf "\n\n"

	rm qstat_save.txt

	sacct --format="JobID,JobName%40,State" | sed '/CANCELLED/d' | sed '/FAILED/d' | sed '/COMPLETED/d' >> qstat_save.txt
	
	while IFS="" read -r p || [ -n "$p" ]
	do
       		#printf '%s\n' "$p"
		identifier=$( echo "$p" | cut -d ' ' -f1 )
		#printf "${identifier}\n"
		if grep -q "$identifier" "qstat_save.txt"; then
			echo "${identifier} already running" 
  		else
			script=$( echo "$p" | cut -d ' ' -f2 )
			echo "Running ${script}"
			eval "./${script}"
  		fi
	done < submit_list_qp4.txt 


	eval "./prod_Run_New_Jobs.sh"


	break
	sleep 10m


done

