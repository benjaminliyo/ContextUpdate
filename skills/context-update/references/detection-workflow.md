# Detection Workflow

Detailed expansion of the Core Workflow in SKILL.md. Each step is
mandatory; skipping steps is the most common failure mode.

---

## Step 1 — Enumerate

Use `discovery-rules.md` to assemble the watch list. **Print the final list
to the user before doing anything else.** This is the transparency
checkpoint: the user can call out a missing file or an unexpected inclusion
before any analysis runs.

Output format: see "Output Shape" in `discovery-rules.md`.

### In-flow editing

After printing the list, prompt for actions. The user may issue any number
of edits before continuing:

```
Edit the watch list? Reply with any of:
  drop N                      — stop watching row N (queues [[ignore]])
  freeze N "reason"           — keep watching but never edit (queues [[freeze]])
  watch PATH [k=v ...]        — add a path (queues [[watch]])
  proceed                     — continue to Step 2 with the list as shown
```

Reply parsing:

- `drop 3` — remove row 3 from the in-memory watch list AND queue an
  `[[ignore]]` block for its path.
- `freeze 5 "historical record"` — mark row 5 `frozen = true` in memory
  AND queue a `[[freeze]]` block with the given reason.
- `watch RULES.md kind=convention severity=high owns="error envelope"`
  — append to the in-memory watch list AND queue a `[[watch]]` block.
  Bare `watch PATH` is allowed; defaults apply.
- `proceed` — stop accepting edits; continue to Step 2.

Rules:

- Queued config edits are NOT written to `.contextupdate.toml` here. They
  accumulate and are persisted in Step 7 with a single confirmation
  prompt. The reason: the user may change their mind mid-flow; one diff
  to review is safer than N writes.
- In-memory changes ARE applied immediately so Steps 2–6 use the
  corrected list.
- If the user adds a path that conversation-derived discovery would have
  flagged at low confidence anyway, dedupe; the explicit `watch` row wins
  and gets `source = "config (queued)"`.
- If `.contextupdate.toml` does not exist yet, a queued edit will create
  it (with `[meta] version = 1`) in Step 7.

---

## Step 1.5 — Classify document type

For each watched file, classify by document type before extracting
decisions. Type determines the edit strategy in Step 5 and is the single
biggest lever against the "appending instead of revising" failure mode.

Types: `instruction | plan | architecture | changelog | readme | tasks`.
See `document-types.md` for signals (filename, headings, length, config
overrides) and per-type edit strategies.

Output internally (not shown to user unless ambiguous):

```
CLAUDE.md
  type: instruction
  signals: filename CLAUDE.md; imperative voice; "use X, not Y" bullets
  edit_strategy: rewrite-in-place

docs/plans/api-refactor.md
  type: plan
  signals: docs/plans/ path; ## Phase 1, ## Phase 2 headings
  edit_strategy: revise-affected-sections-in-place

CHANGELOG.md
  type: changelog
  signals: filename CHANGELOG; ## [Unreleased]; Keep-a-Changelog format
  edit_strategy: append-per-format
```

If any file is ambiguous (filename suggests one type, content reads as
another), ask one consolidated question covering all ambiguous files
(see `report-format.md` "Step 1.5 classification-ambiguity prompt").
Don't re-ask within the same run.

**Why this matters.** Without classification, the most common drift-fix
failure is appending an "Update:" or "v2:" section to an instruction
file — the file then describes two contradictory states and forces
every future session to reconcile. Classification binds edit strategy to
file role: instructions get rewritten, changelogs get appended, plans
get revised in place.

---

## Step 2 — Extract Conversation Decisions

Walk this conversation top-to-bottom. For each candidate decision, produce a
structured row:

```
- subject:     "test runner"
  claim:       "use vitest, not jest"
  turn:        [#42, user]
  quote:       "let's switch to vitest"
  supersedes?: "earlier preference for jest"
```

### Inclusion rule

**Only claims with explicit user agreement count.** Either:
- The user stated the claim directly, OR
- The assistant proposed it and the user explicitly assented in a later turn.

Reasonable-sounding assistant suggestions the user never confirmed do NOT
count. When in doubt, drop the row.

### Quoting rule

`quote` must be the exact text from the turn. **Never paraphrase.** The
quote is what makes a finding auditable.

### Subject normalization

Pick the shortest noun phrase that another reader could match against a
file's topic. Examples: `test runner`, `error envelope`, `module layout`,
`coding style: classes`. Avoid implementation detail (`vitest config flag`).

---

## Step 3 — Compare Per File

For each watched file:

1. **Read fresh.** Do not rely on content read earlier in the conversation —
   files may have changed.
2. For each decision row from Step 2, classify the file's stance:
   - `contradiction` — file asserts the opposite of the decision.
   - `stale` — file describes state that the decision changes (e.g., a
     module name, a dependency, an architectural fact).
   - `superseded` — file records a preference the decision overrides.
   - `missing-new-decision` — file's `owns` topic covers this subject but
     the decision is absent.
   - `aligned` — file already says what the decision says. (Not a finding;
     do not emit.)
3. Record a finding row with: file path, decision row reference, classification,
   exact line range from the file, exact quoted snippet, proposed replacement.

A file may produce multiple findings; preserve order by line number.

### Semantic staleness — qualitative markers vs. quantitative facts

A common miss: the file says "**new** hire" / "**junior** engineer
ramping up" / "**just started** at X" / "**learning** Rust", and the
conversation reveals a quantitative fact that no longer fits the marker
— "I'm **tech lead** on the migration", "almost a **year** in", "we
**shipped v2** last quarter". These are `stale`, not
`missing-new-decision`.

Examples:
- File: "I'm a **junior** engineer ramping up on the codebase." Chat:
  "I'm **leading the migration** as tech lead." → `stale` — `junior`
  and `tech lead` are mutually exclusive descriptors.
- File: "I **just started** at Acme." Chat: "we **shipped v2 last
  quarter**." → `stale` — multi-month implication contradicts "just
  started".
- File: "**Considering switching to** Postgres." Chat: "we **migrated
  to** Postgres **last quarter**." → `stale` — decision has been made
  and executed.

The reason this gets missed: the literal subjects on each side aren't
textually identical (`seniority` vs `migration ownership`), so a
shallow comparison reads them as different topics and reports `aligned`
or `missing-new-decision`. **Compare on implication, not on exact
subject phrasing.** If a qualitative marker in the file no longer fits
a quantitative fact in chat, flag it.

See `examples/junior-to-lead-tenure-drift.md` for a worked walkthrough.

---

## Step 4 — Severity

Default severity by category:

| Category | Default severity |
|---|---|
| `contradiction` | high |
| `superseded` | high |
| `stale` | medium |
| `missing-new-decision` | medium |

Overrides:
- A `severity` in the matching `[[watch]]` entry replaces the default.
- Findings on `kind = convention` or `kind = personal` are bumped to `high`
  if the default would be lower.

---

## Step 5 — Report

Use the template in `report-format.md`. The user-facing output is a
brief per-file summary with two-step approval:

**Step A** — for each file with findings, emit a section listing
findings by number with a 2–5 word subject and a one-line description.
Internal scaffolding (category, severity, exact line ranges, exact
quoted snippets, proposed replacements) is computed but NOT shown.

**Step B** — interpret reply per file:
- `yes` / `apply all` — apply every finding in this file.
- `no` / `skip` — skip this file.
- `apply N M` / `1 and 3 only` — apply listed; skip the rest.
- `reword N to <X>` — apply with the user's revised text for that finding.
- `freeze` / `ignore` — skip and queue `[[freeze]]` or `[[ignore]]`.

Files with zero findings are not listed at all. Per-file approval is
the iron law — no batch "apply across all files at once" affordance.

The proposed replacement for each finding is shaped by the file's
document type (Step 1.5):
- `instruction` / `architecture` / `readme` — rewrite in place.
- `plan` — revise affected sections in place; flag "(plan iteration)"
  if the change spans >30% of the plan.
- `changelog` — append a new entry under the matching heading.
- `tasks` — add/remove/check per the file's convention.

If there are zero findings, emit a one-line positive confirmation rather
than a silent return — the user should know the check ran.

---

## Step 6 — Apply on Approval

For each approved finding (from `yes`, partial selection, or revised
reword):

1. **Re-read the file.** If its content has changed since Step 3, abort this
   finding and report `aborted: file changed since report`. Do not retry
   without showing the new state to the user.
2. Apply the edit per the file's document-type strategy from Step 1.5.
   Instructions and architecture rewrite in place; changelogs append per
   format; plans revise affected sections. Never append "Update:" / "v2:"
   sections to non-changelog files.
3. Refuse to write to any path with `frozen = true` unless the invocation
   was `/context-update --override-frozen` AND the user explicitly
   confirmed the override for this specific file.
4. Print a per-file one-liner summary:

```
CLAUDE.md: 2 applied, 1 skipped
docs/plans/api-refactor.md: 0 applied (file changed since report; re-run)
```

After all approvals are processed, print a single-line total.

---

## Step 7 — Persist queued config edits

Only runs if Step 1 or Step 5 queued any `[[ignore]]`, `[[freeze]]`, or
`[[watch]]` blocks. If the queue is empty, skip this step silently.

1. Read the current `.contextupdate.toml` fresh (or stage a new file if
   absent, headed with `[meta] version = 1`).
2. Compute the merged content with the queued blocks appended in the
   order they were queued. Preserve existing comments and blank lines —
   surgical append only, never reformat.
3. Print a single diff of the full pending change. Group queued blocks
   by type:

```
Pending config changes for .contextupdate.toml (3 queued):

  + [[ignore]]
  +   path = "docs/legacy/initial-design.md"
  + # queued: Step 1 drop 4
  +
  + [[freeze]]
  +   path   = "LICENSE"
  + reason = "legal text"
  + # queued: Step 5 finding 2
  +
  + [[watch]]
  +   path = "RULES.md"
  +   kind = "convention"
  + # queued: Step 1 watch RULES.md

Write these changes to .contextupdate.toml? [ y / n / edit ]
```

4. Allowed replies:
   - `y` — write the file. Print `.contextupdate.toml: 3 blocks added`.
   - `n` — discard all queued edits. In-memory state for this run is
     preserved (you still get your report and applies), but nothing
     persists to disk.
   - `edit` — user supplies a revised diff; apply it verbatim.

5. **Iron law applies to config writes too.** No write without explicit
   approval. Re-read before writing; abort if the file changed since
   step 1.

---

## Idempotency

Re-running `/context-update` on the same conversation, against the
post-apply tree, must produce *only* findings that were previously skipped
or that arose from new decisions. The skill is not "done" — it is a
checkpoint.
