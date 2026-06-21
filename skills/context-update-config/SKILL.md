---
name: context-update-config
description: Use when the user wants to add or remove a watched or ignored file in `.contextupdate.toml` for the context-update skill without running the full drift-detection workflow; when the user types `/context-update-config` or says things like "watch CHANGELOG.md", "stop watching docs/legacy/old-plan.md", "ignore docs/legacy/**", "unignore docs/legacy/**", or "show the context-update watchlist"
---

# Context Update — Config Editor

One-shot editor for `.contextupdate.toml`. Does NOT invoke the
`context-update` skill body. Does NOT run drift detection. Only edits
the config.

## Invocation modes

**Slash command** (Claude Code only — Codex/Cursor/Kimi/OpenCode/Pi do
not auto-discover `commands/*.md`):

    /context-update-config list
    /context-update-config watch add CHANGELOG.md
    /context-update-config watch drop docs/legacy/old-plan.md
    /context-update-config ignore add docs/legacy/**
    /context-update-config ignore drop docs/legacy/**

**Skill invocation** (runtimes that enumerate skills — Codex, Cursor,
Kimi, OpenCode, Pi, and also Claude Code): invoke this skill by name
(`context-update-config`) with the same subcommand string as the slash
form.

**Natural language** (any runtime, any agent — when the user says
something equivalent in conversation):

    "add CHANGELOG.md to context-update's watchlist"
    "stop watching docs/legacy/old-plan.md"
    "ignore docs/legacy/** in context-update"
    "unignore docs/legacy/**"
    "show context-update's watchlist"

All three modes route to the same logic below.

## Subcommands

### `list`
Read `.contextupdate.toml` and print:
- All `[[watch]]` entries with their `kind` and `severity` if set
- All `[[ignore]]` entries
- All `[[freeze]]` entries with their `reason`

If `.contextupdate.toml` does not exist, print a one-line note pointing
to `.contextupdate.toml.example` as a template (the skill still works
with zero config via auto-discovery — config is optional). Do not
create the file from `list`; it's read-only.

Format as a single readable block. No file write.

### `watch add <path>`
1. Verify the path exists and is a file (not a directory). If not,
   refuse, print the resolved absolute path so the user can confirm,
   and exit without editing.
2. Read `.contextupdate.toml`. If absent, create it with a `[meta]`
   block (`version = 1`) before the new entry.
3. If a `[[watch]]` entry with the same `path` already exists, refuse
   with a one-line "already watched" message. No edit.
4. Append a new `[[watch]]` block with just `path = "<path>"`. Do not
   guess `kind` / `severity` / `owns` — the classifier handles type
   detection at run time. The user can hand-edit later if they want
   stronger annotations.
5. Print one-line confirmation: `Added <path> to [[watch]] in
   .contextupdate.toml.`

### `watch drop <path>`
1. Read `.contextupdate.toml`. If absent or no matching `[[watch]]`
   entry, check whether the path would be auto-discovered (well-known
   probe, preloaded context, or conversation-derived). If yes, refuse
   and suggest `ignore add <path>` instead — `watch drop` cannot
   suppress an auto-discovered file. If no, print "not in watchlist"
   and exit.
2. If a matching `[[watch]]` entry exists, remove it. Preserve all
   other blocks, comments, and ordering.
3. Print one-line confirmation.

### `ignore add <glob>`
1. Read `.contextupdate.toml`. If absent, create with a `[meta]`
   block.
2. If an `[[ignore]]` entry with the same `path` already exists,
   refuse with "already ignored". No edit.
3. Append a new `[[ignore]]` block with `path = "<glob>"`.
4. Print one-line confirmation.

### `ignore drop <glob>`
1. Read `.contextupdate.toml`. If absent or no matching `[[ignore]]`
   entry, print "not in ignore list" and exit.
2. Remove the matching `[[ignore]]` entry. Preserve other blocks,
   comments, ordering.
3. Print one-line confirmation.

## TOML editing rules

- Always re-read `.contextupdate.toml` immediately before writing.
  The iron-law principle against blind writes applies to the config
  file too: if it changed since the read at step 1, refuse and re-run.
- Preserve comments, blank lines, and block ordering. Make the
  smallest possible edit: append a block, or remove the targeted
  block. Do not reformat or "normalize" untouched blocks.
- Where the runtime supports it, write atomically (write to a temp
  file, then rename). Otherwise a direct write is acceptable.

## Things this skill does NOT do

- Does NOT invoke `skills/context-update/SKILL.md`.
- Does NOT scan the conversation for drift.
- Does NOT run discovery or classification.
- Does NOT edit any watched context file (CLAUDE.md, AGENTS.md, etc.).
  The iron law about per-file user approval for watched files is
  irrelevant here — this skill only touches `.contextupdate.toml`,
  and invoking this skill IS the approval.
- Does NOT touch `[[freeze]]` entries. Freeze management stays in the
  full skill workflow until v0.2.
- Does NOT guess `kind`, `owns`, or `severity` for new `[[watch]]`
  entries. The user can hand-edit the TOML later for stronger
  annotations.
- Does NOT copy from `.contextupdate.toml.example`. Mutators create a
  minimal config from scratch (`[meta]` + the new entry). The example
  file is a hand-edit reference only.

## Schema reference

See `skills/context-update/references/config-schema.md` for the full
`.contextupdate.toml` schema.
