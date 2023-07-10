
while true
do

ssh -i ~/ssh_key.txt bon39708@kern-login-001.ur.de << EOF
  cd BMN 
  ./auto_submit_qp4.sh >> log_auto_submit_qp4.txt
EOF


	sleep 10m
done
