# openclaw-restart-supervisor

A small recovery layer for OpenClaw that helps agents resume interrupted work after a restart.

It combines three ideas:
- a persistent task ledger
- a bootstrap self-check hook
- a communication rule that prioritizes user-visible progress updates

## Why this exists

Long-running agent work can survive in files more reliably than in session context.

This project makes restart recovery explicit:
- write long tasks to disk
- inspect unfinished work on bootstrap
- remind the agent to report status before going silent again

## Components

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

It reads the ledger, finds unfinished work, and injects a virtual bootstrap file so the agent sees restart recovery instructions before handling new long tasks.

### 3. Progress-first communication

If a job is still active and `userUpdated` is `false`, the agent should send a short progress note before continuing silent work.

## Flow

```text
Start long task
-> write/update ledger entry
-> keep lastAction and nextStep fresh
-> restart happens
-> hook reads ledger on bootstrap
-> unfinished work is injected into startup context
-> agent sends progress note if needed
-> agent resumes work
-> task is marked done
```

## Repository layout

```text
hooks/restart-supervisor/HOOK.md
hooks/restart-supervisor/handler.js
scripts/task_ledger.py
examples/.supervision/pending-jobs.json
PENDING.md
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
- Update `lastAction`, `nextStep`, and `userUpdated` after meaningful steps
- Before restarting the gateway, send a short progress note if the user is waiting
- After restart, check unfinished entries before taking on new long tasks
- Mark tasks `done`, `cancelled`, or `superseded` when they are no longer active

## Notes

- This project does not force outbound messaging on its own.
- Instead, it injects recovery instructions at bootstrap so the agent can prioritize communication.
- If you want fully automatic message delivery, add a message-sending layer that reads the same ledger.

## License

MIT
