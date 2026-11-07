# Security and Threat Model

## Scope and assumptions

The platform assumes payment card data is handled by a PCI-compliant processor and is never stored or transmitted by this application. The AWS account, Terraform state, workloads, and operational identities remain in scope.

## Trust boundaries

| Boundary | Control | Failure concern |
|---|---|---|
| Internet to ALB | HTTPS termination, ALB security group, certificate | Application-layer attacks require WAF before real merchant traffic |
| ALB to EKS | Private subnets and port-specific security group rule | Incorrect target registration or broad node ingress |
| EKS to RDS | Private subnets and PostgreSQL-only ingress | Compromised workload reaching other data services |
| Operators to AWS | IAM, CloudTrail, separate state keys | Over-privileged credentials or state exposure |
| Pods to secrets | IRSA and a secret-specific ARN | Service-account or namespace misconfiguration |

## Allowed traffic matrix

| Source | Destination | Protocol | Port | Purpose |
|---|---|---:|---:|---|
| Internet | Public ALB | TCP | 80 | Redirect HTTP to HTTPS |
| Internet | Public ALB | TCP | 443 | Client HTTPS |
| Public ALB | EKS node/workload path | TCP | 8080 | Application traffic |
| EKS nodes | RDS PostgreSQL | TCP | 5432 | Database connections |
| EKS nodes | Internet through NAT | TCP | 443 | AWS APIs and package access |
| Terraform operator | S3 state bucket | TCP | 443 | State and S3 lockfile operations |

All other inbound paths should be denied by default. Security group changes must be reviewed against this table and the architecture diagram.

## High-priority threats

- Public EKS API exposure: disabled by default; any exception requires explicit, narrow CIDRs.
- State disclosure: S3 encryption, versioning, private access, and separate environment keys are mandatory.
- Credential leakage: use IRSA and Secrets Manager; do not commit `terraform.tfvars`, state, or plan files.
- Destructive production changes: production RDS deletion protection and reviewed plans reduce the blast radius.
- Application attacks: add AWS WAF and application-layer controls before production merchant traffic.

## Review triggers

Revisit this model when card data handling changes, a new ingress path is introduced, environments share networking, or CI receives AWS credentials.