# State Machine

## Task status

Active states:
- `running`
- `blocked`
- `needs_reply`

Closed states:
- `done`
- `cancelled`
- `superseded`

## Communication state

- `userUpdated=true` means the user already received a meaningful progress update
- `userUpdated=false` means recovery should prioritize a short status note

## Recovery order

1. Read unfinished jobs
2. Decide whether to resume, close, or report
3. If `userUpdated=false`, send progress first
4. Continue task execution
5. Close or refresh the ledger entry
