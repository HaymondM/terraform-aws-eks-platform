aws_region   = "us-east-1"
environment  = "dev"
project_name = "eks-platform"

# Networking
vpc_cidr = "10.0.0.0/16"
az_count = 2

# EKS
kubernetes_version     = "1.29"
endpoint_public_access = true
public_access_cidrs    = ["0.0.0.0/0"] # Restrict in production
log_retention_days     = 7

# Node group
node_instance_types = ["t3.medium"]
node_capacity_type  = "SPOT"
node_disk_size      = 50
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 4
