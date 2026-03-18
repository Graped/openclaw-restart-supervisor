# Pending Work Protocol

Use this with `.supervision/pending-jobs.json`.

## Long-task rule

- Before starting a task likely to take more than 2 minutes, add or update a ledger entry.
- Required fields: `id`, `title`, `status`, `startedAt`, `lastUpdatedAt`, `lastAction`, `nextStep`, `userUpdated`, `chatId`.
- Valid active statuses: `running`, `blocked`, `needs_reply`.
- Close a task with `done`, `cancelled`, or `superseded`.

## Recovery rule

- On startup, inspect unfinished entries first.
- If any unfinished entry has `userUpdated: false`, send a short progress update before doing more silent work.
- If a restart interrupted a task, say what was interrupted and what happens next.
