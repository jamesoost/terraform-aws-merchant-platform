# AWS Merchant Platform Infrastructure

A production-ready, scalable AWS infrastructure for a merchant-facing web platform using Terraform. Designed for security, reliability, and cost efficiency.

## Overview

This repository contains Infrastructure as Code (Terraform) for a merchant platform running on AWS. The platform is deployed across three environments (dev, staging, prod) in the `eu-west-1` region with high availability across two Availability Zones.

### What this repo creates

- **Networking**: VPC spanning 2 AZs with public (ALB), private application, and private database subnets
- **Compute**: EKS cluster with managed node groups (production-grade Kubernetes orchestration)
- **Container registry**: ECR repositories with automatic image scanning and lifecycle policies
- **Database**: RDS PostgreSQL with encryption, backup retention, multi-AZ failover (prod), and auto-rotated passwords
- **Load balancing**: Internet-facing Application Load Balancer with HTTPS termination and ALB access logs
- **Security**: Least-privilege security groups, Network ACLs, VPC Flow Logs, encryption at rest (KMS), IRSA-ready IAM access, Secrets Manager-backed application secrets
- **Observability**: CloudWatch Container Insights, EKS audit logs, CloudTrail, VPC Flow Logs, metric alarms, SNS notifications
- **State management**: S3 backend with S3 lockfiles and encryption
- **Cost management**: AWS Budgets with spend alerts, Cost Anomaly Detection

## Architecture

See [architecture/diagram.md](architecture/diagram.md) for a detailed Mermaid diagram showing the topology, traffic flows, and networking design across both availability zones.

## Security Posture

### Compliance Assumption

This platform assumes card data is **never stored or transmitted** by the application - a PCI-compliant processor (Stripe, Adyen, etc.) handles tokenization, keeping the platform under a SAQ A/A-EP model. Infrastructure stays in-scope for network segmentation, audit logging, encryption, and access control (all covered below). If card data is ever handled directly, this design is insufficient and needs AWS WAF, penetration testing, and ASV vulnerability scans before go-live.

### Data Encryption

| Layer | Encryption | Status |
|---|---|---|
| **EKS Secrets** | KMS envelope encryption (etcd) | Enabled |
| **RDS storage** | AWS KMS customer-managed key | Enabled |
| **ALB access logs** | S3 SSE-S3 (AES256) | Enabled |
| **Terraform state** | S3-SSE with KMS | Enabled |
| **In-transit** | TLS 1.2+ (ACM certificate on ALB) | Enabled |

### Audit & Logging

- **CloudTrail**: All AWS API calls logged to S3 with object lock (prevents tampering)
- **EKS control plane audit logs**: All `kubectl` and API server interactions captured (api, audit, authenticator, controllerManager, scheduler)
- **VPC Flow Logs**: IP-level traffic captures for network forensics
- **ALB access logs**: Request-level detail (source IPs, response codes, latency) shipped to S3
- **Container Insights**: Pod and node metrics captured by CloudWatch

## Prerequisites

### Local tools

- Terraform >= 1.10
- AWS CLI v2 (with credentials configured)
- `kubectl` >= 1.24
- `aws-iam-authenticator` (installed automatically by aws-cli)

### AWS account setup

- **Route 53 hosted zone** - must pre-exist for your merchant domain
- **ACM certificate** - must pre-exist, pointing to your domain (TLS termination on ALB)
- **IAM principal** with permissions:
  - EC2, EKS, RDS, ALB, IAM, KMS, S3, CloudWatch, CloudTrail, VPC, ECR, Secrets Manager, SNS
  - Recommend: start with `AdministratorAccess` for initial bootstrap; narrow down post-deployment

### AWS region & AZs

- Region: `eu-west-1` (Ireland)
- AZs: `eu-west-1a`, `eu-west-1b`

## Bootstrap

### Step 1: Initialize remote state (one-time)

This step is only needed when you intentionally create the fresh AWS bootstrap. Nothing in this repository is deployed by the validation workflow.

```bash
cd terraform/modules/remote-state
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

This creates:
- S3 bucket for remote state
- KMS key for S3 encryption

Output will display the S3 bucket name and KMS key details.

### Step 2: Configure backend for dev/staging/prod

Update `terraform/environments/{dev,staging,prod}/backend.tf` using your 12-digit AWS account ID. Replace the placeholder exactly as shown below; do not leave braces or any other text in place.

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-<ACCOUNT_ID>"  # Example: terraform-state-123456789012
    key            = "dev/terraform.tfstate"
    region         = "eu-west-1"
    use_lockfile   = true
    encrypt        = true
  }
}
```

Use the same exact pattern for each environment: `terraform-state-<ACCOUNT_ID>`, where `<ACCOUNT_ID>` is your AWS account number without spaces or punctuation.

### Step 3: Deploy per environment

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with the real ACM ARN, alert address, and approved values.
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Repeat for `staging/` and `prod/`.

On Windows PowerShell, use `Copy-Item terraform.tfvars.example terraform.tfvars` instead of `cp`.

### No-deployment validation

When no AWS account or remote state bucket is available, use the offline checks below. They validate Terraform syntax, modules, provider constraints, and variable definitions without contacting AWS or creating resources:

```powershell
terraform fmt -check -recursive
terraform -chdir=terraform/modules/remote-state init -backend=false -input=false
terraform -chdir=terraform/modules/remote-state validate
terraform -chdir=terraform/environments/dev init -backend=false -input=false
terraform -chdir=terraform/environments/dev validate
terraform -chdir=terraform/environments/staging init -backend=false -input=false
terraform -chdir=terraform/environments/staging validate
terraform -chdir=terraform/environments/prod init -backend=false -input=false
terraform -chdir=terraform/environments/prod validate
```

An AWS-backed `terraform plan` cannot be run as part of no-account validation. Before committing or deploying infrastructure changes, run it with AWS credentials, a bootstrapped S3 state bucket, a real account ID in the backend, and environment-specific `terraform.tfvars` files. Review the plan especially carefully for potentially destructive networking changes such as the environment-specific VPC CIDRs. `plan` is review evidence only; it does not deploy resources.

## Operations and CI

- [Terraform operator guide](terraform/README.md) covers bootstrap, plan/apply, and state safety.
- [Security and threat model](docs/security-and-threat-model.md) records trust boundaries and allowed traffic.
- [Operations runbook](docs/operations-runbook.md) covers incidents, restore, and deployment validation.
- [CI operations guide](docs/ci-operations.md) explains checks, plan artifacts, and failure triage.

The GitHub Actions workflow runs formatting, validation, linting, security scans, and credential-free speculative plans. It never applies Terraform and has no deployment credentials.

## Deployment

### Pre-deployment checklist

- [ ] ACM certificate ARN obtained (use `aws acm list-certificates --region eu-west-1`)
- [ ] Route 53 hosted zone ID obtained
- [ ] IAM credentials configured in AWS CLI
- [ ] Remote state S3 bucket created and S3 lockfile permissions confirmed (bootstrap step above)
- [ ] `terraform/environments/{dev,staging,prod}/terraform.tfvars` reviewed and tailored

### Terraform workflow

```bash
cd terraform/environments/{ENV}

# Initialize backend
terraform init

# Validate configuration
terraform validate

# Plan changes
terraform plan -out=tfplan

# Review plan output, then apply
terraform apply tfplan

# Retrieve outputs
terraform output
```

### Post-deployment validation

```bash
# Configure kubectl to access EKS cluster
aws eks update-kubeconfig --name merchant-{ENV} --region eu-west-1

# Verify cluster connectivity
kubectl get nodes

# Check RDS endpoint
terraform output rds_endpoint

# Retrieve ALB DNS name
terraform output alb_dns_name

# Create Route 53 alias record pointing ALB to your domain
# (Manual step: ALB DNS → Route 53 CNAME/alias record)
```

## State Management

### Design

- **Backend**: S3 with server-side encryption (KMS) and versioning enabled
- **Locking**: S3 lockfiles prevent concurrent applies
- **State keys per environment**: `dev/terraform.tfstate`, `staging/terraform.tfstate`, `prod/terraform.tfstate`; each state uses a matching S3 lockfile
- **Isolation**: Separate state files eliminate cross-environment blast radius (no workspaces)

### State file contents

The state file contains sensitive data (RDS password secret ARN, KMS key IDs, etc.):
- **Never** commit `.tfstate` files to git
- **Always** enable S3 versioning (enabled by `modules/remote-state`)
- **Always** encrypt S3 bucket with KMS (enabled by `modules/remote-state`)
- Access state bucket via IAM, no public access

### Retrieve outputs without state

```bash
cd terraform/environments/prod
terraform output -json | jq .rds_endpoint.value
```

## Secret Handling

### RDS password

- **Method**: `manage_master_user_password = true` on `aws_db_instance`
- **Behavior**: AWS RDS generates a random 16+ character password and stores it in AWS Secrets Manager
- **Terraform visibility**: Terraform never sees the plaintext password; the secret ARN is output
- **Rotation**: AWS RDS automatically rotates passwords (zero-downtime)
- **Application access**: Use AWS Secrets Manager SDK or External Secrets Operator in EKS to retrieve password

```bash
# Retrieve password from Secrets Manager (if needed)
aws secretsmanager get-secret-value \
  --secret-id rds!db-{instance-id} \
  --region eu-west-1 \
  --query SecretString --output text | jq -r .password
```

### Pod-level secrets (IRSA)

- **Method**: IAM Roles for Service Accounts (IRSA) + Secrets Manager
- **Flow**: Pod → OIDC provider → IAM role → Secrets Manager read permission
- **Implementation**: The Terraform framework provisions an IRSA-ready role and a Secrets Manager secret for the application workload, with the role scoped to read only the designated secret
- **Secret provisioning**: Application secret password is generated in Terraform at apply time (not committed in `terraform.tfvars`)
- **No hardcoded secrets**: Application pods never see static credentials or API keys

### Kubectl secrets (if needed)

- Kubernetes Secrets are encrypted at rest in etcd via KMS envelope encryption (enabled by `modules/eks`)
- Base64 encoding is **not encryption** avoid storing sensitive data directly in Kubernetes Secrets

### `.gitignore` - what not to commit

```
*.tfvars
*.tfstate*
.terraform/
!.terraform.lock.hcl  # Must commit this
**/.DS_Store
```

**Important**: `.terraform.lock.hcl` **must be committed** as it locks provider versions and ensures reproducible builds. Only `.terraform/` directory (not the lock file) goes in `.gitignore`.

## Production Readiness

### High availability & failover

| Component | dev | staging | prod |
|---|---|---|---|
| NAT Gateways | 1 (single AZ) | 1 | 2 (one per AZ) |
| RDS multi-AZ | false | false | true (standby replica) |
| RDS backup retention | 7 days | 7 days | 7 days |
| EKS nodes | min 1, desired 2, max 3 | min 2, desired 2, max 5 | min 3, desired 3, max 10 |
| ALB health checks | HTTP 200 | HTTP 200 | HTTP 200 |

### Observability & monitoring

- **CloudWatch alarms** trigger SNS email notifications for:
  - RDS CPU > 80% for 5 minutes
  - RDS free storage < 10GB
  - ALB 5xx error rate > 1% for 2 minutes
  - EKS node CPU > 85% for 5 minutes
- **Container Insights** tracks pod and node metrics in real-time
- **EKS control plane audit logs** ship to CloudWatch for forensics
- **Cost anomaly detection** alerts on unusual AWS charges

### Deletion protection

Resources marked with `lifecycle { prevent_destroy = true }`:
- RDS instance (prod) - prevents accidental database deletion
- S3 state bucket - prevents loss of Terraform state

S3 lockfiles are transient backend objects used to coordinate concurrent state operations. They are not Terraform resources and are not protected by `prevent_destroy`.

If deletion is necessary, manually remove the lifecycle rule first:
```bash
terraform apply -replace=aws_db_instance.main
```

### Performance & operational visibility

- **RDS Performance Insights** (prod) - query-level performance visibility at no extra cost
- **RDS Enhanced Monitoring** - OS-level metrics (disk I/O, swap, etc.)
- **EKS Container Insights** - pod and node resource utilization
- **VPC Flow Logs** - network traffic patterns for capacity planning

### Disaster recovery

- **RDS backups**: Automated daily snapshots retained for 7 days in region
- **Future**: Cross-region backup replication (Phase 2 improvement)
- **State backup**: S3 versioning on state bucket (recover previous state if needed)

## Assumptions & Trade-offs

| Decision | Why | Trade-off |
|---|---|---|
| **Compute: EKS managed nodes** (not Fargate/EC2 ASG) | DaemonSets work (Container Insights, log shipping), no cold-start latency for checkout flows, cheaper than per-pod Fargate billing at steady load, portable industry-standard skillset | Node patching/SG management overhead vs Fargate; more upfront setup than a plain EC2 ASG, but orchestration/health-checks/service-discovery come for free |
| **RDS-managed master password** (`manage_master_user_password = true`) | Terraform never sees plaintext, AWS rotates automatically, stored in Secrets Manager | Can't preview the password before deploy (by design) |
| **Single NAT (dev/staging), dual NAT (prod)** | ~$32/month saved per lower-tier env; prod gets AZ-level egress resilience | Dev/staging lose egress if their single AZ's NAT fails - acceptable for non-prod |
| **NAT Gateway only, no VPC Endpoints yet** | Simpler initial setup, well-understood operational path | Higher NAT data-processing cost at scale (~$150–200/mo); S3 gateway + ECR/Secrets Manager interface endpoints are the first Phase-2 addition (~$1,200–1,800/yr savings) |
| **Pre-existing ACM cert + Route 53 zone** | Avoids DNS propagation dependencies in Terraform; cleaner separation of concerns | Manual step before first deploy (get cert ARN, create alias record) |
| **No WAF at launch** | Reduces initial scope; ALB security groups give L3/L4 protection | **Mandatory before real merchant traffic** - add before go-live, not deferred indefinitely |
| **Single region (eu-west-1), 2 AZs** | Simpler ops, meets GDPR data residency, RDS Multi-AZ handles AZ failures | No protection against a region-level outage (rare, but total downtime if it happens) |
| **Separate state keys per environment** (not Terraform workspaces) | Eliminates accidental cross-environment `destroy`; fully independent state files | Slightly more `backend.tf` boilerplate per environment |
| **PCI scope**: processor handles card data, platform stays SAQ A/A-EP | Simplifies compliance scope to network segmentation + audit trail | If card data is ever handled directly, this design needs WAF, pen testing, and ASV scans first |

---

## Environment Separation

### Directory structure

```
terraform/
  environments/
    dev/
      backend.tf       # S3 key: dev/terraform.tfstate
      main.tf
      variables.tf
      terraform.tfvars.example
      terraform.tfvars
      outputs.tf
    staging/
      backend.tf       # S3 key: staging/terraform.tfstate
      main.tf
      ...
    prod/
      backend.tf       # S3 key: prod/terraform.tfstate
      main.tf
      ...
```

### Per-environment values

The environment drift is intentional and documented: dev and staging are low-cost, single-NAT, non-prod defaults; prod is the stricter, higher-availability baseline.

| Setting | dev | staging | prod |
|---|---|---|---|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| NAT Gateways | 1 | 1 | 2 |
| EKS node type | t3.medium | t3.large | m5.large |
| EKS desired nodes | 2 | 2 | 3 |
| EKS max nodes | 3 | 5 | 10 |
| RDS instance | db.t3.micro | db.t3.medium | db.r6g.large |
| RDS multi-AZ | false | false | true |
| RDS deletion protection | false | false | true |
| Alarm email | dev-alerts@example.com | staging-alerts@example.com | prod-alerts@example.com |
| Monthly budget | $500 | $1500 | $5000 |

Use the environment-specific `terraform.tfvars.example` files as the source of truth for safe defaults. Do not commit real `terraform.tfvars` files with secrets or account-specific values.

The VPC CIDR is an environment contract: dev uses `10.0.0.0/16`, staging uses `10.1.0.0/16`, and prod uses `10.2.0.0/16`. Keep subnet ranges inside the matching VPC range. Changing the CIDR of an existing environment can replace networking resources, so review the plan carefully before applying.

---

## Tagging Strategy

Every resource is tagged via a shared `local.common_tags` map (`Environment`, `Terraform = true`, `ManagedBy = "Terraform"`) merged with a resource-specific `Name` tag. This gives consistent environment attribution, flags resources as Terraform-managed (a guard against manual console drift), and keeps cost/inventory reporting queryable by `Environment` in Cost Explorer and Resource Groups.

**Container image tagging**: ECR repositories are `IMMUTABLE` - once a tag (e.g. a git SHA or semver like `v1.4.2`) is pushed, it can't be silently overwritten by a later push. Images should be tagged by git SHA or semver, never `latest`, so a running deployment always maps back to an exact, reproducible build.

**With more time**: add `Owner`/`CostCenter` tags per team and enforce tagging via AWS Config rules or SCPs (see Improvement List).

## Improvement List

What I'd add next, in priority order, and why:

1. **AWS WAF on the ALB** - currently deferred; mandatory before real merchant traffic goes live (OWASP Top 10 protection).
2. **VPC Endpoints** (S3 gateway, ECR/Secrets Manager interface) - removes NAT dependency for AWS API traffic, saves ~$1,200–1,800/year at scale.
3. **Deployment automation** - add a separately governed apply workflow only after remote-state access, approvals, and rollback procedures are ready.
4. **Automated ACM + Route 53** - replace the pre-existing-certificate assumption with `aws_acm_certificate` + DNS validation, removing a manual pre-deploy step.
5. **Cross-region backup/DR** - replicate RDS snapshots to a second region for region-level outage recovery.
6. **Tag enforcement** - Config rules/SCPs to reject untagged resources; add `Owner`/`CostCenter`.
7. **Service mesh / progressive delivery** - Istio or Argo Rollouts for canary deployments once traffic justifies the complexity.
8. **Multi-region failover** - only if RTO/RPO requirements demand it; a lot of added complexity for a platform designed to "start small".
