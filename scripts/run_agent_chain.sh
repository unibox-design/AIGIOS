#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_CMD="${OPENCLAW_CMD:-openclaw}"
OBJECTIVE="${1:-Create a concise implementation plan for AIGIOS Agent Factory autonomous PR-only delivery with gated release, rollback, and backups.}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${AGENT_CHAIN_OUT_DIR:-.artifacts/agent-chain/${TS}}"
SESSION_PREFIX="${AGENT_CHAIN_SESSION_PREFIX:-agent-chain-${TS}}"
TIMEOUT="${AGENT_CHAIN_TIMEOUT:-120}"
THINKING="${AGENT_CHAIN_THINKING:-low}"
REPO_ROOT="${AGENT_CHAIN_REPO_ROOT:-$(pwd)}"

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

build_repo_evidence() {
  local file="$1"
  {
    echo "Repository evidence snapshot:"
    echo "- timestamp_utc: $TS"
    echo "- repo_root: $REPO_ROOT"
    if command -v git >/dev/null 2>&1; then
      echo "- git_sha: $(git -C "$REPO_ROOT" rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"
      echo "- git_branch: $(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
    fi
    echo
    echo "Guardrail files:"
    for f in \
      ".github/workflows/ci.yml" \
      ".github/workflows/release-gated.yml" \
      ".github/workflows/rollback-gated.yml" \
      ".github/workflows/backup-nightly.yml" \
      "scripts/deploy_staging.sh" \
      "scripts/rollback_release.sh"; do
      if [ -f "$REPO_ROOT/$f" ]; then
        echo "- present: $f"
      else
        echo "- missing: $f"
      fi
    done
    echo
    echo "Content checks:"
    if [ -f "$REPO_ROOT/.github/workflows/ci.yml" ]; then
      if grep -Eiq 'name:\s*CI|validate' "$REPO_ROOT/.github/workflows/ci.yml"; then
        echo "- ci_validate_check: present"
      else
        echo "- ci_validate_check: unclear"
      fi
    else
      echo "- ci_validate_check: missing_file"
    fi
    if [ -f "$REPO_ROOT/.github/workflows/release-gated.yml" ]; then
      if grep -Eiq 'environment:\s*production|workflow_dispatch' "$REPO_ROOT/.github/workflows/release-gated.yml"; then
        echo "- release_production_gate: present"
      else
        echo "- release_production_gate: unclear"
      fi
    else
      echo "- release_production_gate: missing_file"
    fi
    if [ -f "$REPO_ROOT/.github/workflows/rollback-gated.yml" ]; then
      if grep -Eiq 'rollback|production' "$REPO_ROOT/.github/workflows/rollback-gated.yml"; then
        echo "- rollback_gate: present"
      else
        echo "- rollback_gate: unclear"
      fi
    else
      echo "- rollback_gate: missing_file"
    fi
    if [ -f "$REPO_ROOT/.github/workflows/backup-nightly.yml" ]; then
      if grep -Eiq 'schedule|backup' "$REPO_ROOT/.github/workflows/backup-nightly.yml"; then
        echo "- backup_schedule: present"
      else
        echo "- backup_schedule: unclear"
      fi
    else
      echo "- backup_schedule: missing_file"
    fi
  } > "$file"
}

classify_decision() {
  local text="$1"
  if echo "$text" | grep -Eiq '\bNO[- ]?GO\b'; then
    echo "NO-GO"
    return
  fi
  if echo "$text" | grep -Eiq '\b(CONDITIONAL[ -]?GO|GO WITH CONDITIONS?)\b'; then
    echo "CONDITIONAL-GO"
    return
  fi
  if echo "$text" | grep -Eiq '\bGO\b'; then
    echo "GO"
    return
  fi
  echo "UNKNOWN"
}

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

build_repo_evidence "$OUT_DIR/repo_evidence.txt"
EVIDENCE_TEXT="$(cat "$OUT_DIR/repo_evidence.txt")"

echo "[agent-chain] running governor"
"$OPENCLAW_CMD" agent --local --agent governor \
  --session-id "${SESSION_PREFIX}-governor" \
  --timeout "$TIMEOUT" \
  --thinking "$THINKING" \
  --message "Make a governance decision for enabling autonomous coding in this repo.

Return exactly one headline decision token: GO, CONDITIONAL-GO, or NO-GO.
Then provide concise conditions/evidence.

Objective:
$OBJECTIVE

Planner output:
$PLAN_TEXT

Builder output:
$BUILD_TEXT

QA output:
$QA_TEXT

Repository evidence:
$EVIDENCE_TEXT" \
  --json > "$OUT_DIR/governor.json"

GOV_TEXT="$(jq -r '.payloads[0].text // ""' "$OUT_DIR/governor.json")"
if [ -z "$GOV_TEXT" ]; then
  echo "[agent-chain] governor returned empty payload" >&2
  exit 1
fi

DECISION="$(classify_decision "$GOV_TEXT")"

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

echo "[agent-chain] governor decision: $DECISION"
echo "[agent-chain] see $OUT_DIR/summary.md"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "out_dir=$OUT_DIR" >> "$GITHUB_OUTPUT"
  echo "decision=$DECISION" >> "$GITHUB_OUTPUT"
fi
