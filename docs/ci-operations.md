# CI Operations Guide

## Pipeline behavior

`.github/workflows/terraform-ci.yml` runs on pull requests and pushes to `main`. It performs:

- recursive Terraform formatting check;
- `terraform init -backend=false` and `terraform validate` for every environment;
- TFLint and tfsec checks;
- upload of the tfsec scanner report as a short-lived artifact.

There is deliberately no apply job, plan job, state access, AWS credential, or deployment secret in this workflow.

## Why there is no plan job

No infrastructure is deployed yet, and no AWS OIDC-federated CI role or remote-state backend exists. A `terraform plan` run without real credentials cannot reflect a real account, real state, or real IAM permissions, so an earlier credential-free "speculative plan" was removed along with the `ci_mode` placeholder logic it required in the `alb` module. That approach produced a plan that looked like a safety check but was not one, while permanently adding CI-only branches to production module code.

A real `terraform plan` job will be added once the `remote-state` module and a least-privilege, OIDC-federated read-only IAM role are provisioned for at least `dev`. At that point plan uses genuine credentials and real state, with no faking required.

## Local pre-commit vs. CI responsibilities

Local `pre-commit` hooks only run `terraform fmt` and `tflint`, since both are static checks that need no provider downloads. `terraform validate` is network- and provider-dependent, so it runs exclusively in CI to avoid coupling commit-time reliability to local disk space and registry availability. Expect semantic validation errors to surface on push, not at commit time.

## Failure triage

1. Formatting or validation failure: run the failing command locally from the repository root.
2. TFLint or tfsec failure: fix the configuration or document a narrowly scoped, reviewed exception.
3. Artifact failure: rerun the workflow after checking the job log and available artifact storage.

## Ownership and changes

Infrastructure owners review Terraform, scanner exceptions, and workflow changes. Security owners review IAM, network boundaries, secrets, and scanner suppressions. Changes to apply automation or AWS credentials require a separate design and approval.