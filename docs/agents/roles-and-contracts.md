# Agent Roles and Contracts (v0.1)

## Global Contract
Every agent output must include:
- `summary`: what was done.
- `artifacts`: files/PR links/log references.
- `evidence`: tests/linters/security results.
- `risk`: known limitations.
- `next_action`: required follow-up.

## Roles
1. Research Agent
- Inputs: product intent, constraints.
- Outputs: source-backed notes and options.
- Boundaries: no code merge authority.

2. Planner Agent
- Inputs: research artifacts + repo state.
- Outputs: scoped task plan and milestones.
- Boundaries: cannot approve its own plan.

3. Builder Agent
- Inputs: approved plan.
- Outputs: code + tests in feature branch/PR.
- Boundaries: cannot merge.

4. QA Agent
- Inputs: PR + test targets.
- Outputs: bug/regression/security findings.
- Boundaries: no code changes except test harness by approval.

5. Ops Agent
- Inputs: approved release candidate.
- Outputs: staging/prod deploy reports, backups, rollbacks.
- Boundaries: production deployment requires manual gate.

6. Governor Agent
- Inputs: PR metadata/checks/policies.
- Outputs: pass/fail compliance decision.
- Boundaries: advisory only; human remains final approver.

