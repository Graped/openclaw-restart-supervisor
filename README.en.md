# openclaw-restart-supervisor

A lightweight restart recovery layer for OpenClaw built around three ideas: a task ledger, a bootstrap self-check, and progress-first reporting.

Its goal is simple: when an agent is interrupted by a restart, session abort, or runtime failure, the work should not silently disappear and the user should not be left wondering whether anything is still happening.

## What problem it solves

This project combines three small but important pieces:

- a persistent task ledger for long-running work
- a startup check for unfinished jobs
- a rule that tells the agent to send a short progress update before resuming silent work

Together they create a recovery loop like this:

```text
long task starts
-> state is written to the ledger
-> restart or interruption happens
-> startup hook inspects unfinished jobs
-> recovery reminder is injected into bootstrap context
-> if the user has not been updated, report first
-> resume work
```

## Recommended install path

If you want the fastest setup, use the install script:

```bash
bash scripts/install.sh /path/to/openclaw-workspace
```

If you are already working with an exported workspace path:

```bash
OPENCLAW_WORKSPACE=/path/to/openclaw-workspace bash scripts/install.sh
```

Uninstall:

```bash
bash scripts/uninstall.sh /path/to/openclaw-workspace
```

## Script options

Both scripts support:

```bash
bash scripts/install.sh --help
bash scripts/install.sh --dry-run /path/to/openclaw-workspace
bash scripts/uninstall.sh --help
bash scripts/uninstall.sh --dry-run /path/to/openclaw-workspace
```

## AI-oriented install guidance

If you are another coding agent and your task is to install this project into an OpenClaw workspace, prefer the included scripts over handwritten copy commands.

Target workspace paths after installation:

```text
<workspace>/PENDING.md
<workspace>/scripts/task_ledger.py
<workspace>/hooks/restart-supervisor/HOOK.md
<workspace>/hooks/restart-supervisor/handler.js
<workspace>/.supervision/pending-jobs.json
```

`install.sh` will:

1. Resolve the target workspace path
2. Create the required directories
3. Copy the protocol, hook, and helper files
4. Preserve an existing `.supervision/pending-jobs.json`
5. Mark `task_ledger.py` executable
6. Install and enable the hook
7. Restart the gateway
8. Run `openclaw hooks list` and `openclaw hooks check`

## Manual install

If you do not want to use the scripts, follow the Chinese `README.md` for the full manual copy-and-enable flow.

## How it works

```text
1. Agent starts a long-running task
2. Task state is written to .supervision/pending-jobs.json
3. Work is interrupted by restart, crash, or manual stop
4. On the next bootstrap, the hook inspects unfinished jobs
5. Recovery instructions are injected into startup context
6. If userUpdated=false, the agent reports progress first
7. The agent resumes, closes, or escalates the task
```

## Repository layout

```text
hooks/restart-supervisor/HOOK.md
hooks/restart-supervisor/handler.js
scripts/install.sh
scripts/uninstall.sh
scripts/task_ledger.py
examples/.supervision/pending-jobs.json
PENDING.md
docs/design.md
docs/state-machine.md
docs/github-release-checklist.md
```

## Notes

- This project does not force outbound messaging by itself
- It injects recovery reminders at bootstrap and relies on the agent to act on them
- If you want fully automatic reporting, add a message-sending layer that reads the same ledger

## License

MIT
