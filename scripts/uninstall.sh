#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/uninstall.sh [--dry-run] /path/to/openclaw-workspace
  OPENCLAW_WORKSPACE=/path/to/openclaw-workspace bash scripts/uninstall.sh [--dry-run]

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

WORKSPACE="${WORKSPACE:-${OPENCLAW_WORKSPACE:-}}"

if [[ -z "$WORKSPACE" ]]; then
  usage >&2
  exit 1
fi

run "openclaw hooks disable restart-supervisor || true"
run "rm -f \"${WORKSPACE}/hooks/restart-supervisor/HOOK.md\""
run "rm -f \"${WORKSPACE}/hooks/restart-supervisor/handler.js\""
run "rmdir \"${WORKSPACE}/hooks/restart-supervisor\" 2>/dev/null || true"
run "rm -f \"${WORKSPACE}/scripts/task_ledger.py\""
run "rm -f \"${WORKSPACE}/PENDING.md\""
run "rm -f \"${WORKSPACE}/.supervision/pending-jobs.json\""
run "openclaw gateway restart || true"

log
log "Uninstalled restart-supervisor from: ${WORKSPACE}"
log "Review the workspace manually if it contained customized files before installation."
if [[ "$DRY_RUN" == "true" ]]; then
  log "No changes were applied because --dry-run was used."
fi
