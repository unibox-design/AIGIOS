# Governance Policy (v0.1)

## Required Gates
- Branch protection on `main`.
- Required checks: lint, test, typecheck, security scan.
- At least one human reviewer before merge.
- Deployment jobs require manual approval environment.

## Security Controls
- Secrets only via GitHub/cloud secret stores.
- No plaintext API keys committed.
- Least-privilege tokens for CI and agents.
- Weekly dependency and vulnerability scan.

## Operational Safety
- Daily backup of configs and state.
- Rollback tested at least biweekly.
- Incident runbook ownership explicit.

## Agent Constraints
- Agents cannot bypass branch protections.
- Agents cannot directly mutate production infra without approved workflow.
- All high-risk actions produce a change ticket and rollback plan.
