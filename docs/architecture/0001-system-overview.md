# ADR-0001: AIGIOS Agent Factory v0.1 System Overview

## Decision
Build a separate agent-orchestration repository while keeping the current AIGIOS app repository unchanged.

## Why
- Preserve existing progress and reduce migration risk.
- Keep orchestration/governance concerns separate from product runtime code.
- Allow faster experimentation on agent workflows without destabilizing the app.

## Architecture
1. Control Plane
- OpenClaw gateway(s) route tasks to specialized agents.
- Governor policy enforces merge/deploy gates.

2. Delivery Plane
- Agents create branches/PRs in target repos.
- CI validates quality/security and reports status.

3. Runtime Plane
- Oracle VM runs gateway, runners, backups, observability.
- Deploys only from approved tags/commits.

## Data/Control Flow
1. Intake issue/task opened on GitHub.
2. Planner creates implementation plan.
3. Builder proposes PR with tests.
4. QA validates and files findings.
5. Governor checks policy compliance.
6. Human approves merge.
7. Ops deploys to staging; production requires second approval.

## Non-Goals (v0.1)
- Fully autonomous prod deploys.
- Tokenized incentives/reputation economy.
- Hostile multi-tenant trust model.

