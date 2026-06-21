# Document Types

Classification of each watched file determines the edit strategy.
Misclassifying produces the most visible failure mode: appending to an
instruction file (turning it into a changelog), or rewriting a changelog
(erasing history).

Runs as **Step 1.5** in `detection-workflow.md` — between enumeration
and decision-extraction. Output feeds the report template (Step 5) and
the apply step (Step 6).

## The six types

| Type | Purpose | Edit strategy |
|---|---|---|
| `instruction` | Rules, preferences, facts the agent loads as current state every session. `CLAUDE.md`, `AGENTS.md`, personal preferences, `.cursorrules`, `.cursor/rules/*.mdc` | **Rewrite in place.** Keep concise. Stale facts become the new fact; never annotate. |
| `plan` | Working plan for a specific feature or refactor | **Revise affected sections in place.** v1 → v2 means the existing plan text is rewritten to be the v2 plan, not a new section appended. |
| `architecture` | Description of current system or module design | **Rewrite affected sections.** Reads as if the doc always described current state. |
| `changelog` | Chronological record of changes / releases | **Append per existing format.** Match heading level, date format, section grouping. Never rewrite past entries. |
| `readme` | Project intro for newcomers | **Rewrite in place.** Outdated install / usage steps become the new steps; don't keep both. |
| `tasks` | Outstanding work list | **Add / remove / check items** per file convention. |

## Classification signals, in priority order

1. **Filename patterns** (strongest signal)
   - `CHANGELOG*`, `RELEASE-NOTES*`, `RELEASES*`, `HISTORY*`, `CHANGES*`, `NEWS*` → `changelog`
   - `README*` → `readme`
   - `TODO*`, `TASKS*`, `*-todo.md`, `*-tasks.md` → `tasks`
   - `ARCHITECTURE*`, `DESIGN*` → `architecture`
   - Files under `docs/plans/`, `plans/`, or matching `*plan*.md` → `plan`
   - `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursorrules`,
     `.cursor/rules/*.mdc`, `~/.claude/CLAUDE.md` → `instruction`
   - Otherwise fall through to content signals.

2. **First heading + first ~200 chars**
   - `## [version]` / `## [Unreleased]` / dated headings → `changelog`
   - `## Approach`, `## Steps`, `## Phase N`, `## Implementation` → `plan`
   - `## Architecture`, `## Components`, `## System overview` → `architecture`
   - Declarative rules ("This project uses…", "I prefer…", "Always…",
     "Never…") → `instruction`
   - `## Install`, `## Usage`, `## Getting started` → `readme`
   - Checkbox-heavy with no narrative → `tasks`

3. **`[[watch]] kind` in `.contextupdate.toml`** (explicit user override)
   - `convention` / `personal` / `memory` → `instruction`
   - `plan` → `plan`
   - `architecture` → `architecture`
   - `other` → fall through to content signals.

4. **Length & tone fallback**
   - <500 words and declarative → `instruction`
   - Longer, sectioned, future-tense → `plan` or `architecture` (use
     heading signals to disambiguate).

## Ambiguity → ask once

If signals contradict (e.g. a file under `docs/plans/` whose body reads
like a changelog), surface it in the report and ask once:

```
I can't classify `docs/plans/migration.md` with confidence.
  - filename suggests: plan
  - content reads like: changelog (dated entries, Added/Changed sections)
Treat as `plan`, `changelog`, or `skip` to drop it from this run?
```

One question per ambiguous file. Don't re-ask.

## Per-type edit strategies in detail

### `instruction`
The file is read as current state every session. Future sessions expect
truth, not a chronicle.

- Never add "(updated $DATE)", "v2:", or "Recent decisions" markers.
- A stale sentence is rewritten as if it had always said the new thing.
- New facts go in the natural topical section. If none exists, add one
  with a topical heading — never "Updates" or "Changelog".
- Keep total length similar to the original. Replacing 2 bullets with
  3 is fine; replacing 2 bullets with 12 means tighten before proposing.

### `plan`
It's *the* plan, not a history of plans.

- v1 → v2 architectural shift: rewrite the plan's text. The reader sees
  the v2 plan, not v1 + v2 stitched together.
- Adding scope to an existing phase: integrate into that phase's section.
- Completed phases: leave the text unchanged unless the conversation
  changed how they were actually executed.
- If the change rewrites more than ~30% of the plan, ask once:
  *"This looks like a plan iteration. Rewrite the existing plan, or add
  a new section?"*

### `architecture`
Always reads as current. Rewrite affected sections in place.

- Old descriptions get replaced, not annotated.
- If the doc's overall structure should change (whole new layer added
  / module reorganized), ask once before restructuring.

### `changelog`
Match the file's existing format exactly: heading level, date format,
section ordering (Added / Changed / Fixed / Removed / Deprecated /
Security per Keep-a-Changelog, or whatever convention is in use).

- Place new entries per the file's convention — usually top of the
  list, under `## [Unreleased]` or today's date.
- Never rewrite past entries. If a past entry is genuinely wrong,
  flag it as a finding and ask before changing.
- A changelog edit is the only "append" edit. All other types revise.

### `readme`
- Rewrite in place. Concise.
- Outdated install / usage steps become the new steps.
- Don't keep both versions or annotate with "(old)".

### `tasks`
- Detect the file's convention: Markdown checkboxes, plain bullets,
  status sections (`## Todo` / `## Done`).
- Completed items follow the file's pattern (checked off, moved to a
  Done section, or removed).
- New items added in the appropriate section.

## What classification does NOT do

- It does not change *whether* a finding exists (Step 3 is type-agnostic).
- It only changes *how the proposed replacement is shaped* in Step 5.
- It does not auto-reorder content beyond the per-type strategy.
- It does not change the iron law: per-file user approval before any
  write, regardless of type.
