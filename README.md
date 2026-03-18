# openclaw-restart-supervisor

A lightweight restart recovery layer for OpenClaw with task ledger, startup self-check, and progress-first reporting.

It helps an agent recover interrupted work after a restart without silently losing context or leaving the user uninformed.

## What it does

This project combines three simple pieces:

- a persistent task ledger for long-running work
- a bootstrap self-check hook that inspects unfinished jobs
- a progress-first communication rule so the user gets an update before more silent work resumes

Together, they create a lightweight recovery loop:

```text
long task starts
-> ledger entry is written to disk
-> restart or interruption happens
-> bootstrap hook inspects unfinished jobs
-> agent sees recovery reminder on startup
-> agent sends a short progress update if needed
-> work resumes
```

## Why this exists

Long-running agent work often fails socially before it fails technically.

The files may still be there, the task may still be recoverable, and the runtime may already be healthy again - but the user has no idea what happened. This project makes that recovery path explicit.

## Core ideas

### 1. Task ledger

The ledger lives at `.supervision/pending-jobs.json`.

Each job records:

- `id`
- `title`
- `status`
- `startedAt`
- `lastUpdatedAt`
- `lastAction`
- `nextStep`
- `userUpdated`
- `chatId`

### 2. Bootstrap self-check

The `restart-supervisor` hook runs on `agent:bootstrap`.

It reads the ledger, finds unfinished work, and injects a virtual reminder into startup context so the agent notices interrupted work before taking on new long tasks.

### 3. Progress-first reporting

If a job is still active and `userUpdated` is `false`, the agent should send a short progress note before continuing quiet execution.

That one rule is what turns silent recovery into visible recovery.

## Repository layout

```text
hooks/restart-supervisor/HOOK.md
hooks/restart-supervisor/handler.js
scripts/task_ledger.py
examples/.supervision/pending-jobs.json
PENDING.md
docs/design.md
docs/state-machine.md
docs/github-release-checklist.md
```

## Install

Copy the protocol and scripts into your OpenClaw workspace:

```bash
mkdir -p .supervision
cp PENDING.md /path/to/workspace/PENDING.md
cp scripts/task_ledger.py /path/to/workspace/scripts/task_ledger.py
cp -R hooks/restart-supervisor /path/to/workspace/hooks/restart-supervisor
cp examples/.supervision/pending-jobs.json /path/to/workspace/.supervision/pending-jobs.json
chmod +x /path/to/workspace/scripts/task_ledger.py
```

Then install and enable the hook:

```bash
openclaw hooks install /path/to/workspace/hooks/restart-supervisor
openclaw hooks enable restart-supervisor
openclaw gateway restart
```

## Example ledger commands

```bash
python3 scripts/task_ledger.py add install-skills "Finish installing requested skills"
python3 scripts/task_ledger.py update install-skills lastAction "Installed 3 of 6 skills"
python3 scripts/task_ledger.py update install-skills nextStep "Resume the remaining installs after restart"
python3 scripts/task_ledger.py update install-skills userUpdated false
python3 scripts/task_ledger.py list
```

## Recommended operating rules

- Log any task likely to take more than 2 minutes
- Keep `lastAction`, `nextStep`, and `userUpdated` fresh
- Before restarting the gateway, send a short progress note if the user is waiting
- After restart, inspect unfinished entries before starting new long tasks
- Mark jobs `done`, `cancelled`, or `superseded` when they are no longer active

## Notes

- This project does not force outbound messaging by itself
- It injects recovery instructions at bootstrap and relies on the agent to act on them
- If you want fully automatic message delivery, add a message-sending layer that reads the same ledger

## License

MIT
