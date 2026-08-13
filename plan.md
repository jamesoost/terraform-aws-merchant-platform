## Plan: Production-Grade Portfolio Upgrade + CI Baseline

Security-first uplift of this Terraform AWS platform repo to close critical production gaps first, then add a GitHub Actions CI pipeline that enforces quality and security checks with plan artifacts (no apply automation yet). This improves real-world credibility for both engineering and operations audiences while keeping rollout low risk and reversible.

**Problem statement and constraints**
- Problem: Repo is strong structurally but has production-risk defaults and limited operational automation/documentation.
- Why now: Current state is good for learning but not yet polished as a production-grade portfolio artifact.
- Constraints: Keep environment isolation strict; avoid broad refactors; preserve least-privilege, encryption, and production safeguards; CI must be check+plan only.

**Affected layers**
- Application: Consumption guidance only (IRSA + Secrets Manager usage docs), no app runtime code changes.
- Data: RDS hardening controls, retention and protection settings, restoration guidance.
- Infrastructure: EKS endpoint access, per-environment posture, variable validation, security groups.
- Security: IAM least privilege tightening, threat modeling, policy checks in CI.
- Operations: Consolidated runbook content, SLOs, troubleshooting, and deployment validation workflows.
- Delivery: GitHub Actions CI, branch protection checks, contributor standards.

**Options considered**
- Option A: Security-first then CI baseline (selected)
  - Pros: Removes highest production risk immediately, then institutionalizes controls in CI.
  - Cons: Slightly delays visible CI polish by a short interval.
- Option B: CI-first then infra hardening
  - Pros: Fast visible automation signal.
  - Cons: CI would validate unsafe defaults unless hardening follows quickly.
- Option C: Big-bang full overhaul (infra + docs + advanced CI at once)
  - Pros: Shortest elapsed time to end-state.
  - Cons: High change risk, harder review cycles, larger rollback surface.

Recommendation: Execute a security-first hardening wave across Terraform + docs, then add a non-deploying GitHub Actions CI baseline with plan artifacts.
Why now: This sequencing reduces real risk first and then ensures those protections stay enforced through automation.
Tradeoff: Advanced capabilities (integration tests, policy-as-code gate, apply orchestration) are deferred to a second wave.

**Current status snapshot**
- Phase 0: Completed. The work was classified as major, a dedicated branch was created, and the branch was merged and then cleaned up locally.
- Phase 1: Completed and validated. EKS public access now defaults to disabled, public endpoint CIDR input is validated as IPv4-only, and node-group networking preserves required EKS control-plane traffic while keeping the app path restricted.
- Validation evidence: `terraform init -backend=false`, `terraform fmt -check`, and `terraform validate` were run successfully for `dev`, `staging`, and `prod` with the installed Terraform CLI.

**Execution phases and steps**
1. Phase 0: Branching and guardrails (blocks all later phases) - Completed
- Classify work as major and create/switch branch before implementation.
- Dedicated branch decision is approved: create or switch to feature/production-grade-terraform-ci before any implementation.
- Confirm branch protection target branches and required checks naming.
- Define rollback strategy at phase level: each phase must be mergeable independently.

2. Phase 1: Critical Terraform hardening (security-first) - Completed
- Restrict EKS API exposure: remove permissive defaults and require explicit CIDRs per environment, with production-safe validation.
- Introduce environment-specific production posture overrides (prod HA/protection controls, retention policies) and align README tables to actual values.
- Add variable validation for high-risk inputs (CIDRs, counts/sizes, retention bounds, instance type format, email/ARN patterns where appropriate).
- Reduce IAM policy scope in app IRSA role to minimum required CloudWatch/Secrets permissions.
- Audit every security-group rule for directionality, source/destination semantics, and actual traffic path.
- Validate and enforce intended connectivity only: internet -> ALB (80/443), ALB -> EKS workloads (8080), EKS workloads -> RDS (5432).
- Tighten or remove security-group rules where broad east-west access is unnecessary.
- Ensure node-group SG attachment preserves required EKS control-plane and node-to-node traffic while maintaining the app path restriction.
- Dependency: none.

3. Phase 2: Environment contract and onboarding reliability (depends on Phase 1) - In progress
- Add terraform.tfvars.example files for dev/staging/prod with safe, realistic placeholders and guidance.
- Remove placeholder ambiguity in backend setup docs and add deterministic account-ID replacement instructions.
- Add explicit environment matrix for expected drift between dev/staging/prod and enforce through documented defaults.
- Make each environment's documented VPC CIDR an explicit Terraform input and validate that it is an IPv4 /16 range.
- Align staging and prod subnet ranges with their environment VPC CIDRs to prevent overlapping network contracts.
- Document PowerShell onboarding and the backend placeholder replacement requirement.
- Use S3 lockfiles for fresh bootstraps and remove the unused DynamoDB locking resource from the baseline.

4. Phase 3: Portfolio-grade operations documentation (parallel with Phase 4 after Phase 2)
- Deliver a lean 5-doc set to avoid documentation sprawl while preserving production credibility.
- Expand root README with architecture summary, environment matrix, and quickstart links.
- Add/refresh Terraform operator guide with setup, plan/apply, rollback basics.
- Add one consolidated security and threat model doc (including a traffic matrix table of allowed source, destination, protocol, and port).
- Add one consolidated operations runbook doc (incident response, backup/restore, troubleshooting, deployment validation).
- Add one CI operations guide (pipeline behavior, required checks, failure triage, ownership).

5. Phase 4: General CI pipeline (GitHub Actions, checks+plan only) (depends on Phase 2, parallel with late Phase 3)
- Create unified CI workflow triggered on PR and main pushes.
- Jobs: terraform fmt check, terraform validate per environment, tflint, security scanning (tfsec/checkov), terraform plan per environment.
- Upload plan artifacts and scanner reports with retention controls.
- Hard boundary: no apply job and no deployment credentials in CI for this wave.
- Add repository hygiene: pre-commit hooks, PR template, issue templates, CODEOWNERS.

6. Phase 5: Governance integration and quality gates (depends on Phase 4)
- Configure required status checks and review rules in repo settings.
- Ensure plan artifacts are reviewable from PR and that reviewers can compare environment deltas.
- Add a lightweight CI operations document (failure triage, rerun guidance, secrets handling).

7. Phase 6: Validation, rollback rehearsal, and readiness sign-off (depends on all prior phases)
- Validate each environment directory passes fmt/validate/lint/security checks.
- Dry-run plan for dev/staging/prod and confirm no unintended destructive changes.
- Reconcile docs vs code to eliminate contradictions.
- Perform rollback rehearsal docs review (state/versioning + resource protection pathways).

**Critical existing files to modify**
- terraform-aws-merchant-platform/README.md - align claims, environment matrix, deployment/ops guidance.
- terraform-aws-merchant-platform/terraform/README.md - remove contradictions, strengthen workflow clarity.
- terraform-aws-merchant-platform/terraform/environments/dev/main.tf - explicit dev posture where needed.
- terraform-aws-merchant-platform/terraform/environments/staging/main.tf - explicit staging posture where needed.
- terraform-aws-merchant-platform/terraform/environments/prod/main.tf - production hardening and retention/protection overrides.
- terraform-aws-merchant-platform/terraform/environments/dev/variables.tf - validation and constraints.
- terraform-aws-merchant-platform/terraform/environments/staging/variables.tf - validation and constraints.
- terraform-aws-merchant-platform/terraform/environments/prod/variables.tf - validation and constraints.
- terraform-aws-merchant-platform/terraform/modules/eks/variables.tf - secure endpoint defaults and validation.
- terraform-aws-merchant-platform/terraform/modules/iam/main.tf - least-privilege policy refactor.
- terraform-aws-merchant-platform/terraform/modules/security-groups/main.tf - tighten intra-node exposure.

**Planned new files/directories (to be added during implementation)**
- .github/workflows/terraform-ci.yml
- terraform/tflint.hcl
- .pre-commit-config.yaml
- .github/PULL_REQUEST_TEMPLATE.md
- .github/issue_template/*
- .github/CODEOWNERS
- docs/security-and-threat-model.md
- docs/operations-runbook.md
- docs/ci-operations.md
- terraform/environments/dev/terraform.tfvars.example
- terraform/environments/staging/terraform.tfvars.example
- terraform/environments/prod/terraform.tfvars.example

**Verification strategy**
1. Local quality gate by environment directory: terraform fmt -check, terraform init -backend=false, terraform validate. This is the canonical validation path because the portfolio is not deployed.
2. Static checks: tflint (with repo config), tfsec/checkov baseline; review only high/critical blockers initially.
3. Network path checks: verify SG rule directionality and confirm only intended ports/flows are possible for ALB -> EKS -> RDS.
4. Optional plan checks: terraform plan for dev/staging/prod with sanitized tfvars examples adapted to a real sandbox account; no plan or apply is required for the no-deployment portfolio baseline.
5. Documentation consistency audit: ensure all production claims in README/terraform README match actual Terraform defaults and overrides.
6. CI dry run: open test PR and verify required checks, artifact upload, and failure messaging quality.
7. CI boundary check: confirm workflow contains no apply job and uses no deployment credentials.
8. Rollback readiness: verify each phase can be reverted independently without state migration.

**Top risks and mitigations**
- Risk: Hardening changes cause replacement/destructive diffs in existing envs.
  - Likelihood: Medium
  - Impact: High
  - Prevention: Introduce protections with explicit toggles and staged environment rollout.
  - Detection: Plan output contains replacements/destroys.
  - Recovery: Revert phase commit; re-run plan; apply only approved subset.
- Risk: CI security scanners produce noisy false positives and block flow.
  - Likelihood: Medium
  - Impact: Medium
  - Prevention: Start with high/critical thresholds and documented exception process.
  - Detection: Repeated non-actionable failures.
  - Recovery: Tune ruleset and add justified suppressions.
- Risk: Documentation expansion drifts from code over time.
  - Likelihood: Medium
  - Impact: Medium
  - Prevention: CI docs consistency checks and ownership in CODEOWNERS.
  - Detection: Review mismatch findings.
  - Recovery: Update docs in same PR as infra changes.

**Scope boundaries**
- Included: Terraform hardening, environment contract clarity, operational docs, CI checks+plan pipeline.
- Excluded for this wave: automated terraform apply, any CI deployment credentials, full Terratest integration suite, OPA/Sentinel enforcement gate, drift scheduler, and release automation.

**Finalization decisions (locked)**
- Contribution guidance as a standalone file is dropped for this wave.
- Security and threat model document must include a traffic matrix table with allowed source, destination, protocol, and port.
- CI remains non-deploying: no apply job and no deployment credentials.
- Major-work branch gating is approved and required before implementation.
- Prioritization is strict security-first: Phase 1 must meet exit criteria before downstream implementation phases proceed.
- State bootstrap assumes a fresh installation: S3 state, KMS encryption, versioning, and S3 lockfiles are included; migration of existing DynamoDB-backed state is out of scope.

**Phase exit criteria**
1. Phase 0 exit:
- Dedicated branch is created/switched and branch-protection check names are documented.

2. Phase 1 exit:
- EKS endpoint exposure hardening is complete.
- SG rule audit is complete.
- Traffic-path validation confirms only intended ALB -> EKS -> RDS flows on approved ports.

3. Phase 2 exit:
- terraform.tfvars.example files exist for dev, staging, and prod with safe placeholders.
- Environment matrix is consistent across docs and Terraform defaults/overrides.
- Each environment passes `terraform fmt -check` and `terraform validate` with its example variables file supplied.
- Staging and prod subnet CIDRs are inside their matching VPC CIDRs and do not overlap dev.

4. Phase 3 exit:
- Lean documentation set is published and cross-linked from root README.
- Security doc includes the required traffic matrix table.

5. Phase 4 exit:
- CI checks run on PR and main as designed.
- Plan artifacts are uploaded.
- Workflow contains no apply job and no deployment credentials.

6. Phase 5 exit:
- Required status checks and review rules are configured.
- Reviewers can access and compare plan artifacts.

7. Phase 6 exit:
- Validation checks pass for each environment.
- No unintended destructive changes in reviewed plans.
- Rollback approach is documented and testable.

**Decision checkpoints and revisit triggers**
- If CI cycle time exceeds acceptable threshold, split workflows by path/environment.
- If scanner noise is high for >2 consecutive PRs, tune policies before enforcing required status.
- If prod plan shows replacements on critical resources, pause and redesign specific hardening change.

**Handoff readiness**
- Plan is implementation-ready with dependencies and validation order.
- Next agent should execute phase-by-phase with one PR per phase where possible.
