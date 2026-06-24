# Trigger Patterns

When to suspect drift and run `context-update`. Expands SKILL.md's
"When to Use" section with the harder cases — the ones where the
durable file isn't *wrong*, just *incomplete* or *misleading*.

Read this when you suspect drift but aren't sure whether it crosses
the bar for invoking the full workflow.

## Hard triggers — almost always drift

These contradict the file directly. The agent usually catches them
instinctively even without the skill running, but the skill must
still produce a finding (instinct isn't a write).

- Direct preference reversal: *"actually, let's use X instead of Y"*
- Stack swap: *"switch from React to Svelte"*, *"drop pytest, use vitest"*
- Role / identity correction: *"I'm actually a beginner"* against a file
  saying *"experienced developer"*
- Removed dependency: *"we don't use Redis anymore"*
- Renamed concept / module: *"`ApiClient` is now `ApiGateway`"*
- Policy reversal: *"we don't write tests for X anymore"*

## Soft triggers — often missed

These don't *contradict* the file in isolation but make it incomplete
or stale. Easy to miss because each forward-looking statement sounds
reasonable on its own. **The skill exists primarily for these.**

| Pattern | File says | User says | Category |
|---|---|---|---|
| Scope expansion | "local demo" | "playable online" | missing-new-decision |
| Audience shift | "internal tool" | "external customers" | stale |
| Goal pivot | "MVP for personal use" | "ship to App Store" | stale |
| Quality bar | "prototype OK" | "production-grade error handling" | missing-new-decision |
| Deployment target | "runs on my machine" | "deploy to k8s" | stale |
| Timeline | "no rush" | "by Friday" | missing-new-decision |
| Team size | "solo project" | "onboarding two collaborators" | stale |
| Performance target | (silent) | "must handle 10k QPS" | missing-new-decision |

## Conversational tells

Phrases that should make you pause and re-check the watched files:

- *"I'm a beginner"* / *"I've never done this before"* → check
  experience fields in CLAUDE.md, AGENTS.md, `~/.claude/CLAUDE.md`.
- *"I also want to…"* / *"and it should also…"* → scope / goal
  expansion. Check project description, README, plan files.
- *"from now on…"* / *"let's standardize on…"* → policy or
  convention update. Check instruction files.
- *"actually…"* / *"wait, let me clarify…"* → correction of a state
  Claude (or the file) is operating on.
- *"can you also…"* → check that the existing scope description still
  covers the request.
- *"I don't really care about X"* — quietly demotes a previously
  stated priority. Check plans and roadmap files.

## Worked example: local-vs-online

User turn 1: *"I am a beginner for programming, and I want to make the
game also playable online, what should I do?"*

CLAUDE.md before:
> *"I am an experienced software developer. This project is to help me
> build a local demo of a game similar to Plants vs Zombies."*

**Two findings, not one:**

1. **Hard trigger** — *beginner* vs *experienced developer*. Category:
   `contradiction`. (The agent often notices this in its first reply
   without the skill running. Notice ≠ fix — the file still needs an
   edit pass.)
2. **Soft trigger** — *playable online* extends *local demo*. The file
   isn't wrong; it's incomplete. Category: `missing-new-decision` or
   `stale` (the latter if "local" is treated as a hard scope assertion
   rather than a starting point).

A run that catches only #1 is a half-pass. The soft trigger is the
one most likely to slip through if the agent isn't primed.

## Worked example: silent quality-bar shift

User turn 5 (after several refactor turns): *"actually let's add retry
logic and proper error handling everywhere — this needs to be solid"*.

CLAUDE.md before: *"prototype — error handling is best-effort"*.

Single soft finding: quality bar rose without a contradicting
statement. Category: `missing-new-decision`. Easy to miss because
"this needs to be solid" reads as instruction-to-Claude, not as a
durable preference.

## How to use this doc

1. Read it the first time you encounter a soft-trigger pattern in a
   conversation and aren't sure whether to invoke the skill.
2. Once you've recognized the pattern, invoke the skill — don't try
   to fix the file inline. The consolidated report is the consent
   surface; no write happens until the user has seen every diff and
   approved.
3. New patterns observed during testing belong in
   `rationalization-table.md` (if the agent talked itself out of
   firing) or here (if the pattern itself was novel).
