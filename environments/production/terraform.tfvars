aws_region   = "us-east-1"
environment  = "production"
project_name = "eks-platform"

# Networking
vpc_cidr = "10.2.0.0/16"
az_count = 3

# EKS
kubernetes_version     = "1.29"
endpoint_public_access = false          # Private endpoint only in production
public_access_cidrs    = []             # No public access
log_retention_days     = 90

# Node group
node_instance_types = ["m5.xlarge"]
node_capacity_type  = "ON_DEMAND"
node_disk_size      = 100
node_desired_size   = 5
node_min_size       = 3
node_max_size       = 10
