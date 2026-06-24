---
name: context-update-nudge
description: Always-loaded reminder for runtimes that have no SessionStart hook surface (Kimi Code). Plants a short self-reminder so the agent remembers to invoke the full `context-update` skill at session wrap-up when decisions may have drifted from reusable-context files. Do NOT load this skill manually on runtimes that already plant the nudge via SessionStart hooks (Claude Code, Codex, Cursor, Copilot CLI) or via plugin injection (OpenCode, Pi).
---

# Context Update — Session Nudge

## Why this exists
The `context-update` skill is invoke-on-demand. To make sure the agent
actually considers running it before a session ends, every supported
runtime plants a short reminder into the model's working context at
session start. Runtimes with a SessionStart hook (Claude Code, Codex,
Cursor, Copilot CLI) and runtimes with a plugin-injection surface
(OpenCode, Pi) use the same `hooks/nudge.txt` payload.

Kimi Code has no session-start `additionalContext` injection surface,
only `sessionStart.skill`, which loads a whole skill body. This file
**is** that body: it is the reminder, and nothing else.

## The reminder

<CONTEXT-UPDATE-REMINDER>
Before declaring a session done — and whenever the user states a fact
that may already be recorded in a reusable-context file — check whether
this conversation contradicts or extends CLAUDE.md, AGENTS.md,
~/.claude/CLAUDE.md, docs/plans/*, .cursor/rules/*, or personal
instructions.

Watch especially for:
- User self-description (experience level, role, tenure, team size)
- Scope / goal / audience / quality-bar changes
  (local demo → online, prototype → production, internal → customer-facing)
- Tech-stack swaps, tooling switches, deadline shifts
- "Actually…", "from now on…", "we don't do X anymore", "I also want…"

If any apply, suggest /context-update or run the context-update skill.
Never edit a watched file until every proposed change has been shown
and explicitly approved. Pure exploration with no decisions = no action.
</CONTEXT-UPDATE-REMINDER>

## What to do next
Do not act on this reminder now. Continue with whatever the user
actually asked for. When wrap-up conditions are met (the user says
"thanks, that's it", the assistant is about to declare a session done,
or the conversation has clearly produced decisions that may have
drifted), invoke the `context-update` skill — that skill contains the
full detection workflow, watch-list, and report format.

## Keep in sync
The reminder block above must stay byte-for-byte identical to
`hooks/nudge.txt` at the repo root. When you update one, update the
other.
