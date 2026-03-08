#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_CMD="${OPENCLAW_CMD:-openclaw}"
OBJECTIVE="${1:-Create a concise implementation plan for AIGIOS Agent Factory autonomous PR-only delivery with gated release, rollback, and backups.}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${AGENT_CHAIN_OUT_DIR:-.artifacts/agent-chain/${TS}}"
SESSION_PREFIX="${AGENT_CHAIN_SESSION_PREFIX:-agent-chain-${TS}}"
TIMEOUT="${AGENT_CHAIN_TIMEOUT:-120}"
THINKING="${AGENT_CHAIN_THINKING:-low}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[agent-chain] missing required command: $1" >&2
    exit 1
  fi
}

require_cmd "$OPENCLAW_CMD"
require_cmd jq

mkdir -p "$OUT_DIR"

echo "[agent-chain] output dir: $OUT_DIR"

echo "[agent-chain] running planner"
"$OPENCLAW_CMD" agent --local --agent planner \
  --session-id "${SESSION_PREFIX}-planner" \
  --timeout "$TIMEOUT" \
  --thinking "$THINKING" \
  --message "$OBJECTIVE" \
  --json > "$OUT_DIR/planner.json"

PLAN_TEXT="$(jq -r '.payloads[0].text // ""' "$OUT_DIR/planner.json")"
if [ -z "$PLAN_TEXT" ]; then
  echo "[agent-chain] planner returned empty payload" >&2
  exit 1
fi

echo "[agent-chain] running builder"
"$OPENCLAW_CMD" agent --local --agent builder \
  --session-id "${SESSION_PREFIX}-builder" \
  --timeout "$TIMEOUT" \
  --thinking "$THINKING" \
  --message "Use this plan and propose concrete repository/workflow changes.\n\n$PLAN_TEXT" \
  --json > "$OUT_DIR/builder.json"

BUILD_TEXT="$(jq -r '.payloads[0].text // ""' "$OUT_DIR/builder.json")"
if [ -z "$BUILD_TEXT" ]; then
  echo "[agent-chain] builder returned empty payload" >&2
  exit 1
fi

echo "[agent-chain] running qa"
"$OPENCLAW_CMD" agent --local --agent qa \
  --session-id "${SESSION_PREFIX}-qa" \
  --timeout "$TIMEOUT" \
  --thinking "$THINKING" \
  --message "Review this proposal and list top 5 risks with mitigations.\n\n$BUILD_TEXT" \
  --json > "$OUT_DIR/qa.json"

QA_TEXT="$(jq -r '.payloads[0].text // ""' "$OUT_DIR/qa.json")"
if [ -z "$QA_TEXT" ]; then
  echo "[agent-chain] qa returned empty payload" >&2
  exit 1
fi

echo "[agent-chain] running governor"
"$OPENCLAW_CMD" agent --local --agent governor \
  --session-id "${SESSION_PREFIX}-governor" \
  --timeout "$TIMEOUT" \
  --thinking "$THINKING" \
  --message "Given this QA review, return GO/NO-GO with conditions.\n\n$QA_TEXT" \
  --json > "$OUT_DIR/governor.json"

GOV_TEXT="$(jq -r '.payloads[0].text // ""' "$OUT_DIR/governor.json")"
if [ -z "$GOV_TEXT" ]; then
  echo "[agent-chain] governor returned empty payload" >&2
  exit 1
fi

cat > "$OUT_DIR/summary.md" <<SUMMARY
# Agent Chain Dry Run

- Timestamp (UTC): $TS
- Session prefix: $SESSION_PREFIX
- Objective: $OBJECTIVE

## Planner

$PLAN_TEXT

## Builder

$BUILD_TEXT

## QA

$QA_TEXT

## Governor

$GOV_TEXT

SUMMARY

if echo "$GOV_TEXT" | grep -Eiq '\bNO[- ]?GO\b'; then
  echo "[agent-chain] governor decision: NO-GO"
  echo "[agent-chain] see $OUT_DIR/summary.md"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "out_dir=$OUT_DIR" >> "$GITHUB_OUTPUT"
    echo "decision=NO-GO" >> "$GITHUB_OUTPUT"
  fi
  exit 2
fi

echo "[agent-chain] governor decision: GO"
echo "[agent-chain] see $OUT_DIR/summary.md"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "out_dir=$OUT_DIR" >> "$GITHUB_OUTPUT"
  echo "decision=GO" >> "$GITHUB_OUTPUT"
fi
