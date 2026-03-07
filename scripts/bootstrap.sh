#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[bootstrap] Preparing local directories..."
mkdir -p "$ROOT_DIR/runtime/workspaces" "$ROOT_DIR/runtime/state" "$ROOT_DIR/runtime/logs"

echo "[bootstrap] Done."
echo "Next: configure OpenClaw gateway config using configs/openclaw/gateway.example.yaml"
