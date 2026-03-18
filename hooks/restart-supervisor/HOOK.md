---
name: restart-supervisor
description: "Inject restart recovery reminders for unfinished work"
metadata: {"openclaw":{"emoji":"📌","events":["agent:bootstrap"]}}
---

# Restart Supervisor Hook

On agent bootstrap, inspect the persistent task ledger and inject a recovery reminder when unfinished work exists.
