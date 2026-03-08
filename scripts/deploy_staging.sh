#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-staging}"
DEPLOY_ROOT="${DEPLOY_PATH:?DEPLOY_PATH secret/env is required}"
WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
SHA="${GITHUB_SHA:-manual}"
REF_NAME="${GITHUB_REF_NAME:-unknown}"
STAMP="$(date -u +%Y%m%d%H%M%S)"
SHORT_SHA="${SHA:0:12}"
RELEASE_ID="${STAMP}-${SHORT_SHA}"

RELEASES_DIR="${DEPLOY_ROOT}/releases"
CURRENT_LINK="${DEPLOY_ROOT}/current"
PREVIOUS_LINK="${DEPLOY_ROOT}/previous"
STATE_DIR="${DEPLOY_ROOT}/state"
LOG_DIR="${DEPLOY_ROOT}/logs"
RELEASE_DIR="${RELEASES_DIR}/${RELEASE_ID}"

mkdir -p "${RELEASES_DIR}" "${STATE_DIR}" "${LOG_DIR}"

echo "[deploy] target=${TARGET}"
echo "[deploy] workspace=${WORKSPACE}"
echo "[deploy] release_id=${RELEASE_ID}"
echo "[deploy] release_dir=${RELEASE_DIR}"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete \
    --exclude ".git" \
    --exclude ".github" \
    --exclude "runtime" \
    "${WORKSPACE}/" "${RELEASE_DIR}/"
else
  mkdir -p "${RELEASE_DIR}"
  cp -a "${WORKSPACE}/." "${RELEASE_DIR}/"
  rm -rf "${RELEASE_DIR}/.git" "${RELEASE_DIR}/.github" "${RELEASE_DIR}/runtime"
fi

if [ -L "${CURRENT_LINK}" ]; then
  OLD_TARGET="$(readlink "${CURRENT_LINK}")"
  if [ -n "${OLD_TARGET}" ]; then
    ln -sfn "${OLD_TARGET}" "${PREVIOUS_LINK}"
  fi
fi

ln -sfn "${RELEASE_DIR}" "${CURRENT_LINK}"

if [ ! -f "${CURRENT_LINK}/README.md" ] || [ ! -x "${CURRENT_LINK}/scripts/bootstrap.sh" ]; then
  echo "[deploy] health check failed: expected files are missing in current release"
  exit 1
fi

cat > "${STATE_DIR}/last_deploy.json" <<EOF
{
  "target": "${TARGET}",
  "release_id": "${RELEASE_ID}",
  "sha": "${SHA}",
  "ref_name": "${REF_NAME}",
  "deployed_at_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "[deploy] success: ${RELEASE_ID}"
echo "[deploy] current -> $(readlink "${CURRENT_LINK}")"
