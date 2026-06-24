---
description: Check reusable-context files for drift against this conversation
argument-hint: "[--override-frozen]"
---
Invoke the `context-update` skill now. Run the full workflow in
`skills/context-update/SKILL.md` against the current conversation.

If `--override-frozen` was passed, propose edits even for frozen paths.
Frozen files appear in their own section at the end of the consolidated
report; `apply all` does NOT cover them — each frozen path still
requires its own explicit per-file confirmation.
