aws_region   = "us-east-1"
environment  = "staging"
project_name = "eks-platform"

# Networking
vpc_cidr = "10.1.0.0/16"
az_count = 3

# EKS
kubernetes_version     = "1.29"
endpoint_public_access = true
public_access_cidrs    = ["10.0.0.0/8"] # Restrict to internal CIDRs
log_retention_days     = 14

# Node group
node_instance_types = ["t3.large"]
node_capacity_type  = "ON_DEMAND"
node_disk_size      = 50
node_desired_size   = 3
node_min_size       = 2
node_max_size       = 6
