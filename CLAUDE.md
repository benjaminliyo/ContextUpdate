# Working on the ContextUpdate repo

This file is **not** a target of the skill it ships — it's the agent
working instructions for contributing to this repo.

## Iron rules

- **The skill never auto-applies edits.** Every change to a watched file
  requires explicit per-file user approval. Code review enforces this.
- **The `description` frontmatter on SKILL.md states *when* to use the
  skill, never *what* the workflow is.** Workflow summaries in the
  description cause agents to skip the body. See
  `D:/Projects/superpowers/skills/writing-skills/SKILL.md:150-172` for the
  underlying rule.
- **Word budgets are real.** `SKILL.md` body stays under ~500 words. The
  session-start nudge stays under ~150 words.

## Layout invariants

- `skills/context-update/SKILL.md` — frontmatter `name`, `description`
  only; no `version` or `workflow:` fields.
- `skills/context-update/references/` — anything heavy (probe lists,
  schemas, examples) lives here, lazy-loaded.
- `hooks/session-end-nudge` is extensionless on purpose — Claude Code's
  Windows auto-detection rewrites `.sh` commands to `bash <cmd>`.
- `hooks/run-hook.cmd` is a polyglot: cmd.exe on Windows, bash everywhere
  else. Both halves must stay in sync with the superpowers reference.

## Tests

`tests/run-skill-tests.sh` is the grading harness. Each scenario has a
**RED** baseline (no skill loaded) and a **GREEN** target (skill loaded).
Failures are inputs to REFACTOR — capture the rationalization the agent
used and add a row to `references/rationalization-table.md`.

## When changing the skill body

1. Run the three pressure scenarios in baseline mode and save transcripts.
2. Make the change.
3. Re-run with the skill loaded.
4. If a transcript reveals a new rationalization, add it to
   `rationalization-table.md` before merging.

## What lives where

| Concern | File |
|---|---|
| When to use | `skills/context-update/SKILL.md` frontmatter |
| Step-by-step workflow | `references/detection-workflow.md` |
| What to watch | `references/discovery-rules.md` |
| Config syntax | `references/config-schema.md` |
| Report template | `references/report-format.md` |
| Loopholes | `references/rationalization-table.md` |
| Worked examples | `references/examples/*.md` |

## Do NOT

- Add a v0.2 feature (`[[mirror]]` blocks, file-arg slash command,
  always-on monitoring) without a paired pressure scenario.
- Auto-write changes to files outside the project root.
- Extend the frontmatter `description` to summarize workflow.
