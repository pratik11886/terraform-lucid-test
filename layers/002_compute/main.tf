terraform {
  backend "local" {
    path = "terraform.002_compute.tfstate"
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

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.name}-ec2-key"
  public_key = tls_private_key.this.public_key_openssh
}

resource "aws_ssm_parameter" "ec2_private_key" {
  name  = "${var.name}-ec2_private_key"
  value = tls_private_key.this.private_key_pem
  type  = "SecureString"
}

resource "aws_ssm_parameter" "ec2_public_key" {
  name  = "/${var.name}-ec2_public_key"
  value = tls_private_key.this.public_key_openssh
  type  = "SecureString"
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_allow_http"
  description = "Allow HTTP inbound connections"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
      Name = "alb_allow_http"
    },
  )
}

module "alb" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-alb//?ref=v6.6.0"

  name = var.name

  load_balancer_type = "application"

  vpc_id          = local.vpc_id
  subnets         = local.public_subnets
  security_groups = [aws_security_group.alb_sg.id]

  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = local.tags
}

resource "aws_security_group" "ec2_sg" {
  name        = "alb_to_ec2"
  description = "Allow traffic from ALB to EC2"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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
      Name = "alb_to_ec2"
    },
  )
}

module "asg" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-autoscaling//?ref=v5.1.1"

  #Autoscaling group
  name = var.name

  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = local.private_subnets
  target_group_arns         = module.alb.target_group_arns

  # Launch template
  launch_template_name        = var.name
  launch_template_description = "Launch template"
  update_default_version      = true
  security_groups             = [aws_security_group.ec2_sg.id]

  image_id      = "ami-048ff3da02834afdc"
  instance_type = "t2.nano"
  key_name      = aws_key_pair.ec2_key.key_name

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp2"
      }
    },
    {
      device_name = "/dev/sda1"
      no_device   = 1
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 30
        volume_type           = "gp2"
      }
    }
  ]

  tags = local.tags
}
