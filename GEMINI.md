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
- Be concise; don't pad. SKILL.md body should be as short as the
  pressure scenarios allow (currently ~700 words, no hard cap). The
  session-start nudge IS hard-capped at ~150 words — it ships into
  every session's context.

See `CLAUDE.md` for the full working instructions — keep that file and
this one (and `AGENTS.md`) in sync in the same commit.
