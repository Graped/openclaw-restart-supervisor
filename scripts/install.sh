#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/install.sh [--dry-run] /path/to/openclaw-workspace
  OPENCLAW_WORKSPACE=/path/to/openclaw-workspace bash scripts/install.sh [--dry-run]

Options:
  --dry-run   Print the actions without executing them.
  -h, --help  Show this help message.
EOF
}

log() {
  printf '%s\n' "$*"
}

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$*"
  fi
}

DRY_RUN="false"
WORKSPACE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$WORKSPACE" ]]; then
        WORKSPACE="$1"
      else
        log "unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="${WORKSPACE:-${OPENCLAW_WORKSPACE:-}}"

if [[ -z "$WORKSPACE" ]]; then
  usage >&2
  exit 1
fi

run "mkdir -p \"${WORKSPACE}/.supervision\""
run "mkdir -p \"${WORKSPACE}/scripts\""
run "mkdir -p \"${WORKSPACE}/hooks/restart-supervisor\""
run "cp \"${REPO_DIR}/PENDING.md\" \"${WORKSPACE}/PENDING.md\""
run "cp \"${REPO_DIR}/scripts/task_ledger.py\" \"${WORKSPACE}/scripts/task_ledger.py\""
run "cp \"${REPO_DIR}/hooks/restart-supervisor/HOOK.md\" \"${WORKSPACE}/hooks/restart-supervisor/HOOK.md\""
run "cp \"${REPO_DIR}/hooks/restart-supervisor/handler.js\" \"${WORKSPACE}/hooks/restart-supervisor/handler.js\""

if [[ ! -f "${WORKSPACE}/.supervision/pending-jobs.json" ]]; then
  run "cp \"${REPO_DIR}/examples/.supervision/pending-jobs.json\" \"${WORKSPACE}/.supervision/pending-jobs.json\""
else
  log "Keeping existing ledger: ${WORKSPACE}/.supervision/pending-jobs.json"
fi

run "chmod +x \"${WORKSPACE}/scripts/task_ledger.py\""
run "openclaw hooks install \"${WORKSPACE}/hooks/restart-supervisor\""
run "openclaw hooks enable restart-supervisor"
run "openclaw gateway restart"
run "openclaw hooks list"
run "openclaw hooks check"

log
log "Installed restart-supervisor into: ${WORKSPACE}"
if [[ "$DRY_RUN" == "true" ]]; then
  log "No changes were applied because --dry-run was used."
fi
