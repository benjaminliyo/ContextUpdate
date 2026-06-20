# Document Types — Claude.ai

Classification determines how the skill shapes proposed edits. On
Claude.ai the relevant surfaces are almost always `instruction` type —
Project Instructions and Personal Preferences are short, declarative,
loaded fresh every session.

Runs as **Step 1.5** in `detection-workflow.md`.

## The two types relevant to Claude.ai

| Type | Edit strategy |
|---|---|
| `instruction` (default for Project Instructions, Personal Preferences, most pasted blocks) | **Rewrite in place.** Keep concise. Stale facts become the new fact; never append `Update:` / `v2:` markers. New facts go in the natural topical section. |
| `changelog` (rare — only if user pasted a changelog) | **Append per existing format.** Match heading level, date format, section grouping. |

Other types (`plan`, `architecture`, `readme`, `tasks`) exist in the
coding-agent variant but are out of scope here — they live on disk in
a repo, not in a Claude.ai surface.

## Classification signals

- **Project Instructions** — always `instruction`.
- **Personal Preferences / User style** — always `instruction`.
- **Pasted context blocks** — check the block:
  - `## [version]` headings, dated entries, "Added / Changed / Fixed"
    sections → `changelog`.
  - Declarative rules ("use X", "I prefer Y", "always", "never") →
    `instruction`.
  - Anything else → `instruction` by default.
- **Uploaded knowledge files** — classify the same way, but they're
  read-only, so the type only informs *what kind of drift to flag*,
  not a proposed rewrite.

## Ambiguity → ask once

If a pasted block is genuinely ambiguous:

```
I can't classify the pasted block confidently. Treat as `instruction`
(rewrite in place) or `changelog` (append entries)?
```

One question, then proceed.

## The instruction-type rule in detail

This is the load-bearing strategy for Claude.ai. Project Instructions
read by future sessions need to be **current state**, not a history of
what was decided when.

Concretely:

- A stale sentence is rewritten as if it had always said the new thing.
  *Wrong:* keep "The backend uses Java" and append "Update: backend
  changed to Go".
  *Right:* rewrite the line to "The backend uses Go".

- New facts go in the natural topical section. If a `## Design` section
  exists and the new fact is a design decision, integrate it there.
  Don't add a separate `## Recent decisions` or `## v2 scope` section.

- Keep total length similar to the original. Replacing 2 bullets with 3
  is fine; replacing 2 bullets with 12 means you're over-explaining —
  tighten before proposing.

- Never add: `Update:`, `v2:`, `(updated $DATE)`, `Recent decisions`,
  `Changelog`. Those turn the doc into a chronicle.

## Changelog-type rule (rare on Claude.ai)

Only applies if the user pasted an actual changelog. Match the file's
existing convention:

- Heading level of entries
- Date format
- Section ordering
- Whether new entries go at top or bottom

Never rewrite past entries. New decision from the conversation becomes
a new entry only.

## What classification does NOT do

- It does not change *whether* a finding exists.
- It only shapes the proposed replacement text.
- It does not summarize on the user's behalf — the user can always say
  "tighten finding 2" in the two-step approval.
- It does not change the iron law: the model never claims to have
  applied a change. The user always pastes the final block manually.
