#! /bin/bash

lines(){
	for i in $(seq $1); do
		printf "=";
	done;
	echo
}

lines 50 && echo "Deploying BASE" && lines 50
cd layers/001_base
terraform init
terraform plan -out plan
terraform apply plan
read -p "Press [Enter] key to continue... or 'ctrl + c' to cancel" fackEnterKey

lines 50 && echo "Deploying EC2" && lines 50
cd ../002_compute/
terraform init
terraform plan -out plan
terraform apply plan
read -p "Press [Enter] key to continue... or 'ctrl + c' to cancel" fackEnterKey

lines 50 && echo "Deploying RDS" && lines 50
cd ../003_rds/
terraform init
terraform plan -out plan
terraform apply plan
