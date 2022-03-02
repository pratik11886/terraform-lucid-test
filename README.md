# terraform-lucid-test
Deploy VPC, EC2 and RDS using Terraform

### Repo Structure
```
├── README.md
├── layers
│   ├── 001_base
│   │   ├── main.tf
│   │   ├── output.tf
│   │   ├── provider.tf
│   │   └── variables.tf
│   ├── 002_compute
│   │   ├── main.tf
│   │   ├── output.tf
│   │   ├── provider.tf
│   │   └── variables.tf
│   └── 003_rds
│       ├── main.tf
│       ├── output.tf
│       ├── provider.tf
│       └── variables.tf
├── terraform-build.sh
└── terraform-destroy.sh
```

### Run locally from your machine
```
git clone https://github.com/pratik11886/terraform-lucid-test.git

Using AWS console creat an IAM user with full admin access.

Create AWS profile (ex terraform) on your machine:
- aws configure --profile terraform (this will require AWS Access key and Secret key)
- export AWS_PROFILE=terraform

Use below script to deploy all resources in one go
- ./terraform-build.sh  #This script will build all layers starting from network -> compute -> rds

Use below script to destory all resources in one go
- ./terraform-destroy.sh   #This script is use to destroy all resources
```
