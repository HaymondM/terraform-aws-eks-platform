# terraform-aws-eks-platform

Production-ready Terraform project for provisioning a secure, multi-environment EKS cluster on AWS.

## Architecture

```
terraform-aws-eks-platform/
├── backend/                    # Remote state bootstrap (run once)
├── modules/
│   ├── vpc/                    # VPC, subnets, NAT gateways, route tables
│   ├── eks/                    # EKS cluster, security groups, KMS, CloudWatch
│   ├── iam/                    # Cluster role, node role, OIDC provider
│   └── node-group/             # Managed node group with launch template
└── environments/
    ├── dev/                    # Dev environment config + tfvars
    ├── staging/                # Staging environment config + tfvars
    └── production/             # Production environment config + tfvars
```

### What gets provisioned

- VPC with public and private subnets across multiple AZs
- NAT Gateways (one per AZ) for private subnet egress
- EKS cluster with private endpoint option, secrets encryption via KMS, and full control plane logging
- Managed node group with IMDSv2 enforced, encrypted EBS, and detailed monitoring
- IAM roles following least-privilege (cluster role, node role, OIDC provider for IRSA)
- S3 + DynamoDB remote state backend with encryption and versioning

### Environment differences

| Setting               | dev          | staging       | production     |
|-----------------------|--------------|---------------|----------------|
| VPC CIDR              | 10.0.0.0/16  | 10.1.0.0/16   | 10.2.0.0/16    |
| AZs                   | 2            | 3             | 3              |
| Instance type         | t3.medium    | t3.large      | m5.xlarge      |
| Capacity type         | SPOT         | ON_DEMAND     | ON_DEMAND      |
| Node count (desired)  | 2            | 3             | 5              |
| Public API endpoint   | Yes          | Restricted    | No (private)   |
| Log retention         | 7 days       | 14 days       | 90 days        |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) >= 2.x configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for interacting with the cluster
- An AWS account with permissions to create VPC, EKS, IAM, S3, DynamoDB, KMS, and CloudWatch resources

### Required IAM permissions

Your AWS credentials need at minimum:
- `eks:*`
- `ec2:*` (VPC, subnets, security groups, NAT gateways)
- `iam:*` (roles, policies, OIDC providers)
- `s3:*` (state bucket)
- `dynamodb:*` (state lock table)
- `kms:*` (secrets encryption)
- `logs:*` (CloudWatch log groups)

---

## Usage

### Step 1 — Bootstrap the remote state backend

This only needs to be done once per AWS account.

```bash
cd backend
terraform init
terraform apply
```

> The S3 bucket name must be globally unique. Edit `backend/variables.tf` if you need a different name, and update the `bucket` value in each environment's `backend "s3"` block to match.

### Step 2 — Deploy an environment

```bash
cd environments/dev
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

Replace `dev` with `staging` or `production` as needed.

### Step 3 — Configure kubectl

After a successful apply, run the output command:

```bash
terraform output kubeconfig_command
# Example output:
# aws eks update-kubeconfig --region us-east-1 --name eks-platform-dev

aws eks update-kubeconfig --region us-east-1 --name eks-platform-dev
kubectl get nodes
```

---

## Customization

### Changing instance types

Edit the `node_instance_types` in the relevant `terraform.tfvars`:

```hcl
node_instance_types = ["m5.large", "m5.xlarge"]
```

### Restricting API server access

For staging/production, set `public_access_cidrs` to your office or VPN CIDR:

```hcl
endpoint_public_access = true
public_access_cidrs    = ["203.0.113.0/24"]
```

Or disable public access entirely (requires VPN/bastion to reach the API):

```hcl
endpoint_public_access = false
public_access_cidrs    = []
```

### Adding a second node group

Call the `node-group` module a second time in the environment's `main.tf`:

```hcl
module "node_group_gpu" {
  source = "../../modules/node-group"

  cluster_name    = local.cluster_name
  node_group_name = "gpu"
  node_role_arn   = module.iam.node_group_role_arn
  subnet_ids      = module.vpc.private_subnet_ids
  instance_types  = ["g4dn.xlarge"]
  desired_size    = 1
  min_size        = 0
  max_size        = 3
  node_labels     = { "node-type" = "gpu" }
  node_taints = [{
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }]
  tags = local.common_tags

  depends_on = [module.eks]
}
```

---

## Outputs

| Output              | Description                                      |
|---------------------|--------------------------------------------------|
| `vpc_id`            | VPC ID                                           |
| `cluster_endpoint`  | EKS API server endpoint URL                      |
| `cluster_name`      | EKS cluster name                                 |
| `kubeconfig_command`| AWS CLI command to configure kubectl             |
| `oidc_provider_arn` | OIDC provider ARN for IAM Roles for Service Accounts (IRSA) |

---

## Destroying an environment

```bash
cd environments/dev
terraform destroy -var-file="terraform.tfvars"
```

> Do not destroy the `backend` resources until all environment state has been migrated or deleted.

---

## Security notes

- EKS secrets are encrypted at rest using a dedicated KMS key with automatic rotation enabled
- Node instances enforce IMDSv2 (token-required) to prevent SSRF attacks against the metadata service
- Node EBS volumes are encrypted
- S3 state bucket has public access blocked and versioning enabled
- DynamoDB state lock table has encryption and point-in-time recovery enabled
- Production cluster has no public API endpoint by default
- IAM roles use AWS managed policies scoped to the minimum required for EKS operation
