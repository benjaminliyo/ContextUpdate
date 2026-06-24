# Release notes

## v0.1.0 — 2026-06-19

First public scaffold of ContextUpdate.

### What works

- `/context-update` invokes the skill against the live conversation.
- Auto-discovery of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`,
  `CONVENTIONS.md`, `.cursor/rules/*.mdc`, `.cursorrules`,
  `.clinerules`, `.windsurfrules`, `.github/copilot-instructions.md`,
  `docs/plans/*.md`, `plans/*.md`, `.claude/memories/*.md`,
  `docs/conventions/*.md`, `ARCHITECTURE.md`, and (optionally) the
  user-global `~/.claude/CLAUDE.md`.
- Reference-following from those files at depth 2 with cycle protection.
- TOML config (`.contextupdate.toml`) supporting `[[watch]]`,
  `[[ignore]]`, `[[freeze]]`, and `[discovery]`.
- Consolidated-report approval gate: every proposed edit is shown in one
  report (with inline diffs), then a single `apply all` writes the
  approved set. Per-file review is available as a fallback. No
  auto-write.
- SessionStart-planted self-reminder so a wrap-up turn considers the skill
  before declaring done.

### Known limitations

- `[[mirror]]` blocks parse-only; behavior deferred to v0.2.
- No `/context-update FILE1 FILE2 ...` argument form.
- The session-end nudge is a SessionStart-planted reminder; if Claude Code
  ships a real `SessionEnd` hook, migrate to it.
- `include_user_global` defaults to `true`; this may flip to `false` after
  user feedback.
- Test harness assumes the developer pastes transcripts into
  `tests/transcripts/` — automatic subagent dispatch is host-specific.

### Verification (manual)

The "Verification" section in the build plan is the end-to-end check:
seed `~/scratch/cu-verify/` with a `CLAUDE.md` saying "we use jest" and a
plan saying "REST only, no GraphQL"; have a conversation that switches to
vitest and adds GraphQL; confirm 2 high findings rendered in the
consolidated report with inline diffs, the single Apply-all prompt,
idempotency on re-run, and `[[freeze]]` behavior.
