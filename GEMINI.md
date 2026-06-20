# GEMINI.md

Gemini CLI entry point for the `context-update` skill. Mirrors `CLAUDE.md`
and `AGENTS.md` so each runtime finds the working instructions under the
filename it expects.

The skill body lives at `skills/context-update/SKILL.md`. On Gemini CLI,
load it via the standard skill-loading flow (typically from
`~/.gemini/skills/` or `~/.agents/skills/` once this plugin is installed).

## Iron rules (mirrored from CLAUDE.md)

- The skill never auto-applies edits. Every change to a watched file
  requires explicit per-file user approval.
- The frontmatter `description` on SKILL.md states *when* to use the
  skill, never *what* the workflow is.
- Word budgets: SKILL.md body under ~500 words; the session-start nudge
  under ~150.

See `CLAUDE.md` for the full working instructions — keep that file and
this one (and `AGENTS.md`) in sync in the same commit.
