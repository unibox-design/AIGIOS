# AIGIOS Agent Factory v0.1

A clean, isolated workspace for running a governed multi-agent delivery system around AIGIOS.

## Purpose
- Keep existing app work intact (`/Users/proximity/Documents/AIGIOS`).
- Build an autonomous-but-controlled engineering factory using OpenClaw-style multi-agent routing.
- Ensure all code changes, deployments, and operations are gated by human approval.

## Scope (v0.1)
- Multi-agent role model (`research`, `planner`, `builder`, `qa`, `ops`, `governor`).
- GitHub-first governance (PR checks, protected branches, manual deploy approval).
- Oracle server runtime plan with backup/rollback and observability.

## Repository Layout
- `docs/architecture`: system design and data/control flow.
- `docs/agents`: agent responsibilities and boundaries.
- `docs/governance`: policies, risk controls, and approval gates.
- `docs/runbooks`: operational runbooks (deploy, rollback, backup, incident).
- `configs/openclaw`: example gateway/profile/sandbox config templates.
- `configs/agents`: agent prompt/contract templates.
- `scripts`: bootstrap and maintenance scripts.
- `.github/workflows`: CI/CD pipelines with human-in-the-loop controls.

## Principles
- Human approval required for merge/deploy.
- No direct writes to production by autonomous agents.
- All outputs must include provenance and test evidence.
- Default to least privilege.

## Immediate Next Steps
1. Initialize this folder as a separate git repository.
2. Push to GitHub as `aigios-agent-factory`.
3. Apply branch protection (`main` requires checks + manual review).
4. Deploy to Oracle VM and run in staged mode.

