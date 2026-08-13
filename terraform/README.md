# Terraform Infrastructure as Code

This directory contains the Terraform code for the merchant platform infrastructure on AWS.

## Directory Structure

```
terraform/
├── modules/              # Reusable Terraform modules
│   ├── vpc/             # VPC, subnets, NAT gateways, route tables, Flow Logs, Network ACLs
│   ├── security-groups/ # ALB, EKS nodes, RDS security groups
│   ├── alb/             # Application Load Balancer, target groups, listeners
│   ├── eks/             # EKS cluster, node groups, addons, IAM, KMS encryption
│   ├── ecr/             # ECR repositories, lifecycle policies, image scanning
│   ├── rds/             # RDS PostgreSQL instance, KMS encryption, native password management
│   ├── iam/             # IRSA-ready IAM role for application workloads
│   ├── secrets-manager/ # Application secrets stored in Secrets Manager
│   ├── remote-state/    # S3 backend bucket and KMS key (fresh bootstrap module)
│   └── observability/   # CloudWatch alarms, SNS topics, CloudTrail, AWS Budgets
├── environments/        # Environment-specific configurations
│   ├── dev/            # Development environment
│   ├── staging/        # Staging environment
│   └── prod/           # Production environment
├── .gitignore          # Git ignore rules for Terraform files
└── README.md           # This file
```

## Module Overview

All resources use the native `hashicorp/aws` provider directly - no community modules. For a baseline this size, thin native resources are easier to audit line-by-line than a wrapped community module, and nothing here (VPC, ALB, EKS, RDS) is complex enough that a community module would meaningfully simplify it. Provider versions are pinned (`~> 5.0` for `aws`, see `versions.tf`) and locked via `.terraform.lock.hcl`.

### vpc
- Creates VPC with CIDR 10.0.0.0/16
- Creates 6 subnets across 2 AZs (2 public, 2 private-app, 2 private-db)
- Configures Internet Gateway, NAT Gateways, route tables
- Implements Network ACLs for database tier (defence-in-depth)
- Enables VPC Flow Logs for security monitoring

### security-groups
- ALB security group: allows HTTP/HTTPS from internet, forwards to EKS
- EKS node security group: accepts from ALB, talks to RDS, accesses internet via NAT
- RDS security group: accepts PostgreSQL from EKS nodes only

### alb
- Creates internet-facing Application Load Balancer
- Configures HTTPS listener with ACM certificate
- HTTP listener redirects to HTTPS
- S3 bucket for access logs (name pattern: `alb-logs-{environment}-{account_id}`)
- Enforces S3 default encryption for ALB logs with SSE-S3 (AES256)
- Target group for EKS pod-level routing

### eks
- Creates EKS cluster with encryption (KMS envelope encryption for secrets)
- Configures managed node groups with auto-scaling
- Installs addons: vpc-cni, coredns, kube-proxy, amazon-cloudwatch-observability
- Enables control plane logging (api, audit, authenticator, controllerManager, scheduler)
- Creates OIDC provider for IRSA (IAM Roles for Service Accounts)

### rds
- Creates PostgreSQL RDS instance with KMS encryption
- Uses native `manage_master_user_password = true` (AWS manages password in Secrets Manager)
- Multi-AZ support for production (database replication across AZs)
- Performance Insights enabled for production
- Backup retention policy with automated backups
- `prevent_destroy` lifecycle rule for production

### ecr
- Creates ECR repositories for container images
- Immutable image tags by default (`image_tag_mutability = "IMMUTABLE"`) - prevents an existing tag from being silently overwritten
- Lifecycle policy to expire untagged images
- Image scanning on push for vulnerability detection

### iam
- Creates an IRSA-ready IAM role for the application workload
- Grants read access to the application secret in Secrets Manager
- Keeps access scoped to the service account and secret ARN

### secrets-manager
- Creates a Secrets Manager secret for application credentials
- Generates the secret password at apply time when no password is provided
- Avoids hardcoded secret values in committed environment variable files
- Intended for use by the workload through the IAM role and future application integration

### remote-state
- Creates S3 bucket for Terraform state with versioning and KMS encryption
- Creates the S3 state bucket and KMS key used by the S3 backend and its lockfiles
- All resources have `prevent_destroy = true` (bootstrap module)

### observability
- CloudWatch alarms: RDS CPU, storage, ALB errors
- SNS topic for alarm notifications
- CloudTrail for AWS API audit logging (production only)
- AWS Budgets for cost management
- Cost Anomaly Detection

## Environment Configurations

See [Environment Separation](../README.md#environment-separation) in the root README for the full dev/staging/prod comparison (NAT count, instance sizes, Multi-AZ, budgets).

## Getting Started

See [Bootstrap](../README.md#bootstrap) and [Deployment](../README.md#deployment) in the root README for prerequisites, remote-state bootstrap, and the full AWS-backed `init` / `plan` / `apply` workflow per environment.

To create local inputs, copy the matching example file before initializing Terraform. In PowerShell:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Then replace the sample certificate ARN and alert address, and review the environment-specific CIDR and sizing values before running `terraform init`.

For no-deployment validation, run `terraform init -backend=false` followed by `terraform validate` in each environment. A normal `terraform init` and `terraform plan` require an AWS account, configured credentials, and a bootstrapped S3 backend.

## Important Files

- **backend.tf**: S3 state backend configuration. Replace the placeholder `terraform-state-<ACCOUNT_ID>` with your 12-digit AWS account ID exactly; example: `terraform-state-123456789012`.
- **terraform.tfvars.example**: Safe, copyable defaults for each environment. Copy the file to `terraform.tfvars` locally and replace the sample values with your actual account and certificate details.
- **terraform.tfvars**: Environment-specific values. Keep these files free of plaintext secrets and do not commit them to source control.
- **.terraform.lock.hcl**: Provider dependency lock file. **Commit this to version control** for consistency.

## Limitations & Next Steps

This is infrastructure-as-code only, nothing has been deployed. Application deployment automation (Kubernetes manifests, CI/CD) is out of scope for this assessment.

See [Improvement List](../README.md#improvement-list) in the root README for what's prioritized next (WAF, VPC Endpoints, CI/CD, DR, tag enforcement, etc.).

