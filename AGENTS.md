# AGENTS.md

Purpose: Help AI coding agents be immediately productive in this repo while planning changes at full-system scope.

## Scope

These instructions apply to all work in this repository.

## Primary Docs (Link, do not duplicate)

- System and business context: [README.md](README.md)
- Topology and traffic flow: [architecture/diagram.md](architecture/diagram.md)
- Terraform structure and module boundaries: [terraform/README.md](terraform/README.md)

## Working Model

- Think like a systems architect before making edits.
- Evaluate impact across network, compute, data, security, observability, and delivery.
- Prefer small, reversible changes with explicit rollback steps.
- Keep environment separation strict: dev, staging, prod must remain independently safe.

## Planning Standard (Required for non-trivial changes)

Before implementation, produce a short plan that includes:

1. Problem statement and constraints
2. Affected layers (app, data, infra, security, ops)
3. At least 2 options
4. Recommendation
5. Tradeoffs in plain language
6. Risks and mitigations
7. Validation and rollback approach

Use this plain-language format for each recommendation:

- Recommendation: what to do
- Why now: why it is best under current constraints
- Tradeoff: what is sacrificed or deferred

## Terraform Conventions

- Run from the target environment directory under [terraform/environments](terraform/environments).
- Standard workflow: init, validate, plan, apply.
- Keep provider and module behavior consistent with existing patterns.
- Avoid broad refactors unless explicitly requested.
- Never commit state files or secrets.

## Safety Guardrails

- Do not weaken encryption, logging, or least-privilege defaults without explicit request.
- Preserve production protections (for example prevent-destroy and stronger HA defaults).
- Flag any change that increases blast radius, cost, or operational burden.

## Major Work Definition

Treat work as major and require a new branch when any of the following is true:

- Changes affect multiple modules or environments.
- Changes alter security posture, IAM permissions, encryption, or network boundaries.
- Changes can increase blast radius, downtime risk, or monthly cloud cost.
- Changes include state migration, resource replacement, or deletion risk.
- Changes introduce a new platform capability, subsystem, or integration.
- Estimated implementation spans more than one planned step.

If none of the above is true, ask the user whether they still want a dedicated branch.

## Required Pre-Work Prompt

Before implementation starts, use this exact prompt:

"This looks like [major/non-major] work based on current scope. Do you want to create or switch to a dedicated branch now? If yes, I recommend: [feature/fix/chore]/<short-description>."

For multi-step plans, at the end of each step use this exact prompt before the next step:

"Before I start the next step, has the related remote branch been merged, and do you want branch cleanup at this stage? If yes, I will delete the merged local branch and run git fetch --prune."

## Git Workflow Guardrails

- Never commit changes directly as the agent.
- Always ask the user to review changes first, then ask the user to perform the commit themselves.
- For any major new work, always prompt the user to create a new branch before implementation begins.
- Branch naming convention for major new work:
	- `feature/<short-description>` for new capabilities
	- `fix/<short-description>` for bug fixes
	- `chore/<short-description>` for maintenance and refactors
- After completing each planned step, ask whether the related remote branch has been merged before starting the next step.
- After each planned step, ask the user whether branch cleanup is required at that stage.
- If branch cleanup is required and the remote branch is merged, clean local branch state before moving on:
	- Delete the merged local branch.
	- Run `git fetch --prune` to remove stale remote-tracking references.

## Pre-Commit Checklist (User-Run)

- Before any commit, ask the user to run this checklist from the relevant environment directory:
	- `terraform fmt -check`
	- `terraform validate`
	- `terraform plan -out=tfplan`
- Ask the user to review the plan output for unintended changes before committing.
- The agent must not commit on the user's behalf.

## Uncertainty Handling

- If confidence is below 85%, do not assume.
- State what is uncertain, list assumptions explicitly, and ask a clarifying question before proceeding.
- If progress is still needed while awaiting clarification, present options with risks instead of selecting one as final.

## Done Criteria

A change is only done when:

- Plan and decision rationale are documented in simple terms.
- Tradeoffs and risks are explicit.
- Validation steps are listed and practical.
- Rollback path is clear.
