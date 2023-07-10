#!/bin/bash
cd prod_broad_runs

exist=0

for name in *.sh; do
	if [ -f "$name" ]; then
		exist=1
		break	
	fi			
done


if [ $exist -eq 0 ] 
then
	echo "No .sh files found. Exiting."
	exit 
fi

for filename in *.sh; do
    echo ""
    echo $( ls -ld *.sh | wc -l ) "jobs remaining to submit."
    echo ""
    echo "Submitting" $filename
    time=$( grep "TIME FOR SUBMIT" $filename |  awk '{print $NF}' )
    #echo $time
    jobnu_ath=$(sbatch -t $time  $filename)
    jobnu=${jobnu_ath%%.*}
    counter=10
                while [ -z "${jobnu}" ]    
                do	
		    echo		
    		    echo $( ls -ld *pbs | wc -l ) "jobs remaining to submit."
		    echo
                    echo "\tResubmitting.."
                    jobnu_ath=$(sbatch -t $time $filename)
                    jobnu=${jobnu_ath%%.*}
                    sleep ${counter}s
                    counter=$(($counter + 10))
                done
    echo "Success. Jobnumer is" $jobnu
    mv $filename ../prod_broad_old/
    sleep 4s
done
cd ..
