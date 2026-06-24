# Porting to other harnesses

This document has moved. See
[`installing-per-runtime.md`](installing-per-runtime.md) for the current
matrix of shipped files per target (Claude Code, Claude.ai, Codex,
Cursor, Copilot CLI, Gemini CLI) and the install steps for each.

For new harnesses not in that matrix, the porting rules below still
apply.

## What to keep portable

- The frontmatter rule (`description` = "Use when…" only) is
  runtime-agnostic; do not relax it for any harness.
- The "every edit visible before any write" gate is non-negotiable on
  every harness. Whether the runtime can render the consolidated report
  as one interactive question (Claude Code / Kimi) or only as a typed
  prompt (Codex / Cursor / Copilot CLI / Claude.ai web), the report
  must come first and a single approval must cover the listed diffs.
- TOML config is parsed the same way everywhere; do not split the schema
  per runtime.

## What to keep runtime-specific

- The exact hook output JSON shape — Claude Code, Cursor, Codex/Copilot,
  Gemini, and the SDK standard differ. Branch on the env vars the same
  way `hooks/session-end-nudge` does.
- The Windows `run-hook.cmd` polyglot is only needed where the runtime
  rewrites `.sh` commands. Drop it where it isn't.
- Where slash commands aren't a first-class surface, document message-
  invocation as the fallback (e.g. *"run context-update on this
  conversation"*).
