# Changelog

## [1.0.0] - 2026-11-04

### Added
- Generic `iam` module: IAM groups, dynamic groups and policies via `for_each`.
- `locals.tf` template with DEV / UAT / PROD examples and inline syntax guide.
- GitHub Actions workflow: validate, plan on pull requests, approval-gated apply.
- Remote state in OCI Object Storage, pushed back even if apply fails.
- `policy_ids` output, input validation and optional free-form tags.
