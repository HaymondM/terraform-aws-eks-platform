variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name used as a prefix for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS API endpoint"
  type        = bool
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access the public EKS API endpoint"
  type        = list(string)
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
}

variable "node_instance_types" {
  description = "EC2 instance types for the node group"
  type        = list(string)
}

variable "node_capacity_type" {
  description = "Node capacity type: ON_DEMAND or SPOT"
  type        = string
}

variable "node_disk_size" {
  description = "Node disk size in GiB"
  type        = number
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
}
