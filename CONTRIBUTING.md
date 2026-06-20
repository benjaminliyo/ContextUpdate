# Contributing

## Before you open a PR

1. Read `CLAUDE.md` — the iron rules and word budgets are non-negotiable.
2. Read `docs/design-rationale.md` so you don't propose a code-driven
   refactor that defeats the point of the skill.
3. If your change touches `skills/context-update/SKILL.md`, run the
   pressure scenarios (`tests/run-skill-tests.sh`) **both** with and
   without the skill loaded, and attach the transcripts.

## What we accept readily

- New rationalization-table rows backed by a real transcript.
- New pressure scenarios that expose a missed drift category.
- Doc clarifications, especially in `references/examples/`.
- Cross-runtime porting (Cursor, Codex, Gemini) — see
  `docs/porting-to-other-harnesses.md`.

## What needs discussion first

- Changes to the report format (the test harness greps for tokens).
- New top-level config blocks beyond the current schema.
- Anything that weakens the "no auto-write" iron law.

## What we will not accept

- Removing the per-file approval gate.
- Frontmatter `description` fields that summarize workflow.
- Hidden network calls or telemetry.

## Style

- Markdown wraps at ~80 columns where possible.
- Skill bodies stay under ~500 words; nudge stays under ~150.
- Quote conversation turns **exactly** in examples — never paraphrase.

## Commit messages

Imperative present-tense subject ("add plan-supersession example"), one
paragraph of context if the change is non-trivial.
