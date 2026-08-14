## Change summary

Describe the infrastructure or documentation change and the affected environment(s).

## Safety review

- [ ] No secrets, state files, or plan files are included.
- [ ] Environment-specific values and state keys are correct.
- [ ] I reviewed replacements, destroys, IAM, network, encryption, and cost impact.
- [ ] Rollback steps are documented for this change.

## Validation

- [ ] Terraform fmt and validate pass.
- [ ] TFLint and security scans pass or have a reviewed exception.
- [ ] AWS-backed plans were reviewed where infrastructure behavior changes.