terraform {
  backend "local" {
    path = "terraform.003_rds.tfstate"
  }
}

data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = "${path.module}/../001_base/terraform.001_base.tfstate"
  }
}

locals {
  vpc_id          = data.terraform_remote_state.base.outputs.vpc_id
  private_subnets = data.terraform_remote_state.base.outputs.private_subnets
  public_subnets  = data.terraform_remote_state.base.outputs.public_subnets

  tags = {
    Environment = "test"
    Terraform   = "true"
  }
}

resource "random_string" "rds_password" {
  length  = 20
  lower   = true
  number  = true
  special = false
  upper   = true
}

resource "aws_ssm_parameter" "rds_password" {
  name      = "/${var.name}-rds_password"
  overwrite = false
  type      = "SecureString"
  value     = random_string.rds_password.result

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_security_group" "rds" {
  name        = "rds_allow_ec2"
  description = "Allow rds access to ec2"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "rds_allow_ec2"
    },
  )
}

module "db" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-rds//?ref=v3.5.0"

  identifier = var.name

  engine            = "mysql"
  engine_version    = "5.7.25"
  instance_class    = "db.t2.micro"
  allocated_storage = 5

  password = random_string.rds_password.result
  name     = "demodb"
  username = "user"
  port     = "3306"

  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    Environment = "test"
  }

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = local.private_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection
  deletion_protection = true
}
