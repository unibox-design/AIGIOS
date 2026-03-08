#!/usr/bin/env bash
set -euo pipefail

DEPLOY_ROOT="${DEPLOY_PATH:?DEPLOY_PATH secret/env is required}"
CURRENT_LINK="${DEPLOY_ROOT}/current"
PREVIOUS_LINK="${DEPLOY_ROOT}/previous"
STATE_DIR="${DEPLOY_ROOT}/state"

if [ ! -L "${PREVIOUS_LINK}" ]; then
  echo "[rollback] no previous release symlink found"
  exit 1
fi

PREV_TARGET="$(readlink "${PREVIOUS_LINK}")"
if [ -z "${PREV_TARGET}" ] || [ ! -d "${PREV_TARGET}" ]; then
  echo "[rollback] previous release target is invalid: ${PREV_TARGET}"
  exit 1
fi

if [ -L "${CURRENT_LINK}" ]; then
  CUR_TARGET="$(readlink "${CURRENT_LINK}")"
  if [ -n "${CUR_TARGET}" ]; then
    ln -sfn "${CUR_TARGET}" "${PREVIOUS_LINK}"
  fi
fi

ln -sfn "${PREV_TARGET}" "${CURRENT_LINK}"
mkdir -p "${STATE_DIR}"

cat > "${STATE_DIR}/last_rollback.json" <<EOF
{
  "rolled_back_to": "${PREV_TARGET}",
  "rolled_back_at_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "[rollback] success: current -> $(readlink "${CURRENT_LINK}")"
