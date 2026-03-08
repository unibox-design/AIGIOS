# Next Steps (Execution Order)

## 1) Keep Current App Intact
- Continue using `/Users/proximity/Documents/AIGIOS` as your app workspace.
- Treat `agent-factory/` as a separate repository root.

## 2) Initialize Separate Repository
From `/Users/proximity/Documents/AIGIOS/agent-factory`:
1. `git init`
2. `git add .`
3. `git commit -m "chore: bootstrap aigios-agent-factory v0.1"`
4. Create remote repo `aigios-agent-factory` on GitHub
5. `git remote add origin <your-repo-url>`
6. `git branch -M main`
7. `git push -u origin main`

## 3) Apply GitHub Controls
- Protect `main`: require PR, require checks, require 1 human approval.
- Enable GitHub environment `production` with required reviewers.
- Store secrets in GitHub Actions secrets/environment secrets.

## 4) AWS EC2 Bootstrapping
1. Clone `aigios-agent-factory` into `/opt/aigios-agent-factory`.
2. Run `scripts/bootstrap.sh`.
3. Install and configure OpenClaw per official docs.
4. Load/adjust `configs/openclaw/gateway.example.yaml` to match installed schema/version.

## 5) Configure Deployment Secrets (GitHub)
- `DEPLOY_HOST` (EC2 public IP or DNS)
- `DEPLOY_USER` (`ubuntu` for Ubuntu AMI)
- `DEPLOY_SSH_KEY` (private key content, multiline)
- `DEPLOY_PORT` (`22` unless customized)
- `DEPLOY_PATH` (for example `/opt/aigios-agent-factory`)

## 6) Safe Runtime Mode (v0.1)
- Start with read-only research/planning workflows.
- Allow builder to open PRs only.
- Keep deploy workflow manual-only.

## 7) Integrate with Existing AIGIOS App
- Configure builder/qa/ops agents to target the app repo as an external repo.
- Start with low-risk tasks: docs, test coverage, bugfix PRs.
