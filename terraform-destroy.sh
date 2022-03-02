#! /bin/bash

lines(){
	for i in $(seq $1); do
		printf "=";
	done;
	echo
}

lines 50 && echo "Destroying RDS" && lines 50
cd layers/003_rds
terraform destroy --auto-approve
read -p "Press [Enter] key to continue... or 'ctrl + c' to cancel" fackEnterKey

lines 50 && echo "Destroying COMPUTE" && lines 50
cd ../002_compute
terraform destroy --auto-approve
read -p "Press [Enter] key to continue... or 'ctrl + c' to cancel" fackEnterKey

lines 50 && echo "Destroying BASE" && lines 50
cd ../001_base/
terraform destroy --auto-approve
