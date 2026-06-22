# AGENTS.md

Discovery shim for Codex, Copilot CLI, Gemini CLI, and other agent
frontends that look for `AGENTS.md` instead of (or in addition to)
`CLAUDE.md`.

**Reference `CLAUDE.md` for the canonical working instructions for this
repo.** Both files describe the same project, so keeping a second full
copy here would just drift. If a future runtime needs working
instructions that genuinely differ from the Claude Code set, override
or extend them in this file.

The skill's own discovery rules treat `AGENTS.md` and `CLAUDE.md`
equivalently, so an empty shim is enough to satisfy runtimes that
require the filename.
