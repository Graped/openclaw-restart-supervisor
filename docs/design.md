# Design Notes

## Problem

An agent can lose momentum after a gateway restart even when the actual work is recoverable.

The missing piece is usually not task execution, but restart discipline:
- What was in progress?
- What is safe to resume?
- Does the user need a progress update first?

## Design goals

- Keep state in plain files
- Avoid provider-specific dependencies
- Work with bootstrap hooks instead of deep runtime patching
- Separate task state from communication state

## Why `userUpdated` matters

A task can be recoverable while still being socially invisible.

`userUpdated=false` means:
- the work exists
- the agent knows about it
- but the user is still owed a progress update

That is why recovery should prioritize communication before more silent work.
