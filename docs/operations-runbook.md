# Operations Runbook

## Before a deployment

1. Confirm the target environment and matching S3 state key.
2. Copy its `terraform.tfvars.example` to `terraform.tfvars` and replace only approved account-specific values.
3. Run `terraform fmt -check -recursive`, `terraform init`, `terraform validate`, and `terraform plan -out=tfplan`.
4. Review all replacements and destroys. Production plans require an explicit reviewer.
5. Apply the reviewed plan, then record outputs and validation results.

The repository CI workflow is checks-only. It is not a deployment mechanism.

## Post-deployment validation

```powershell
aws eks update-kubeconfig --name merchant-<env> --region eu-west-1
kubectl get nodes
terraform output alb_dns_name
terraform output rds_endpoint
```

Confirm ALB health, application readiness, RDS connectivity from the workload, CloudWatch alarms, and expected cost notifications.

## Incident response

1. Identify the environment and preserve the failing plan, logs, and CloudTrail event IDs.
2. Stop additional applies and notify the service owner and security owner for suspected access or data incidents.
3. For an application issue, inspect ALB 5xx metrics, EKS events, node health, and Container Insights.
4. For a network issue, inspect security groups, route tables, VPC Flow Logs, and the traffic matrix.
5. For a state or Terraform issue, do not delete or recreate the state bucket. Use S3 versioning and the last known-good plan.

## Backup and restore

- RDS automated backups are retained for 7 days; production uses Multi-AZ and deletion protection.
- Restore into an isolated environment first, validate schema and application compatibility, then plan the cutover.
- Terraform state recovery uses S3 object versioning. Identify the correct state version with the platform owner before restoring it.
- Cross-region disaster recovery is not implemented in this baseline; region loss requires a separately approved design.

## Rollback

Prefer applying a reviewed corrective plan. If a Terraform change is unsafe, stop before apply and revert the change in source, then re-run `terraform plan`. For an already-applied change, restore the prior application image or configuration and use a targeted infrastructure rollback only with an approved plan.

## No-deployment validation

Run `terraform init -backend=false` and `terraform validate` for the remote-state module and each environment. These checks do not contact AWS. A real AWS-backed plan is required before infrastructure changes are applied.