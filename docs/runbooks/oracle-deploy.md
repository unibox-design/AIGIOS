# AWS Deploy Runbook (v0.1)

## Target
Single AWS EC2 VM for 3-4 month experimental operation.

## Base Setup
1. Install Docker + Docker Compose plugin.
2. Install Git and configure deploy key with read access.
3. Create directories:
- `/opt/aigios-agent-factory`
- `/opt/aigios-agent-factory/data`
- `/opt/aigios-agent-factory/logs`
4. Configure security group for required ports only.

## AWS Baseline
- Instance type: `t2.micro` or `t3.micro` (free-tier eligible where available).
- OS: Ubuntu 22.04 LTS.
- SSH: allow port `22` from your IP only.
- Public access: open `80/443` only if you expose services.
- Optional: attach Elastic IP for a stable host value.

## Deployment Flow
1. Pull latest approved commit/tag.
2. Run preflight checks.
3. Start services in staging profile.
4. Validate health checks.
5. Promote to production profile after manual approval.

## Backup
- Nightly tar backup of configs/state/log index.
- Retain 14 daily and 8 weekly snapshots.
- Verify restore weekly on staging.

## Rollback
1. Stop current services.
2. Checkout previous known-good tag.
3. Restore last consistent state snapshot.
4. Start services and verify health.
