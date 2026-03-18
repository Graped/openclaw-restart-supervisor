#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${1:-${OPENCLAW_WORKSPACE:-}}"

if [[ -z "${WORKSPACE}" ]]; then
  echo "usage: scripts/uninstall.sh /path/to/openclaw-workspace" >&2
  echo "or set OPENCLAW_WORKSPACE before running." >&2
  exit 1
fi

openclaw hooks disable restart-supervisor || true

rm -f "${WORKSPACE}/hooks/restart-supervisor/HOOK.md"
rm -f "${WORKSPACE}/hooks/restart-supervisor/handler.js"
rmdir "${WORKSPACE}/hooks/restart-supervisor" 2>/dev/null || true
rm -f "${WORKSPACE}/scripts/task_ledger.py"
rm -f "${WORKSPACE}/PENDING.md"
rm -f "${WORKSPACE}/.supervision/pending-jobs.json"

openclaw gateway restart || true

echo
echo "Uninstalled restart-supervisor from: ${WORKSPACE}"
echo "Review the workspace manually if it contained customized files before installation."
