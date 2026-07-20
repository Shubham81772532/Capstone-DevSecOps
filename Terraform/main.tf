terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.52.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source             = "./modules/VPC"
  vpc_cidr_block     = var.vpc_cidr_block
  region             = var.region
  availability_zones = var.availability_zones
}

module "security_group" {
  source         = "./modules/Security-Group"
  vpc_id         = module.vpc.vpc_id
  sg_name        = "hotstar-sg"
  sg_description = "Hotstar Jenkins + SonarQube Security Group"
  ssh_cidr       = ["0.0.0.0/0"]
}

module "ec2" {
  source            = "./modules/EC2"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = module.vpc.public_subnet_ids[0]
  key_name          = var.key_name
  security_group_id = module.security_group.security_group_id
}

module "eks" {
  source             = "./modules/EKS"
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  eks_instance_types = var.eks_instance_types
  desired_size       = var.desired_size
  min_size           = var.min_size
  max_size           = var.max_size
}
