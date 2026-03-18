#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="${1:-${OPENCLAW_WORKSPACE:-}}"

if [[ -z "${WORKSPACE}" ]]; then
  echo "usage: scripts/install.sh /path/to/openclaw-workspace" >&2
  echo "or set OPENCLAW_WORKSPACE before running." >&2
  exit 1
fi

mkdir -p "${WORKSPACE}/.supervision"
mkdir -p "${WORKSPACE}/scripts"
mkdir -p "${WORKSPACE}/hooks/restart-supervisor"

cp "${REPO_DIR}/PENDING.md" "${WORKSPACE}/PENDING.md"
cp "${REPO_DIR}/scripts/task_ledger.py" "${WORKSPACE}/scripts/task_ledger.py"
cp "${REPO_DIR}/hooks/restart-supervisor/HOOK.md" "${WORKSPACE}/hooks/restart-supervisor/HOOK.md"
cp "${REPO_DIR}/hooks/restart-supervisor/handler.js" "${WORKSPACE}/hooks/restart-supervisor/handler.js"

if [[ ! -f "${WORKSPACE}/.supervision/pending-jobs.json" ]]; then
  cp "${REPO_DIR}/examples/.supervision/pending-jobs.json" "${WORKSPACE}/.supervision/pending-jobs.json"
fi

chmod +x "${WORKSPACE}/scripts/task_ledger.py"

openclaw hooks install "${WORKSPACE}/hooks/restart-supervisor"
openclaw hooks enable restart-supervisor
openclaw gateway restart
openclaw hooks list
openclaw hooks check

echo
echo "Installed restart-supervisor into: ${WORKSPACE}"
