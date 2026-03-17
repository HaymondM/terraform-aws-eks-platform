terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-eks-platform"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  cluster_name = "${var.project_name}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name         = "${var.project_name}-${var.environment}"
  cluster_name = local.cluster_name
  vpc_cidr     = var.vpc_cidr
  az_count     = var.az_count
  tags         = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name           = local.cluster_name
  kubernetes_version     = var.kubernetes_version
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_subnet_ids     = module.vpc.private_subnet_ids
  cluster_role_arn       = module.iam.cluster_role_arn
  endpoint_public_access = var.endpoint_public_access
  public_access_cidrs    = var.public_access_cidrs
  log_retention_days     = var.log_retention_days
  tags                   = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  cluster_name            = local.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  tags                    = local.common_tags
}

module "node_group" {
  source = "../../modules/node-group"

  cluster_name    = local.cluster_name
  node_group_name = "default"
  node_role_arn   = module.iam.node_group_role_arn
  subnet_ids      = module.vpc.private_subnet_ids
  instance_types  = var.node_instance_types
  capacity_type   = var.node_capacity_type
  disk_size       = var.node_disk_size
  desired_size    = var.node_desired_size
  min_size        = var.node_min_size
  max_size        = var.node_max_size
  tags            = local.common_tags

  depends_on = [module.eks]
}
