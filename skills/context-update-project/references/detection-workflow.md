# Detection Workflow — Claude.ai

Detailed expansion of the five-step Core Workflow in SKILL.md. Each step
is mandatory; skipping steps is the most common failure mode.

The Claude.ai workflow is shorter than the coding-agent workflow because
there is no filesystem to read, no `.contextupdate.toml` to persist, and
no apply step — the deliverable is always a copy-paste block.

---

## Step 1 — Enumerate visible surfaces

Use `discovery-rules.md` to identify every reusable-context surface
present in this conversation. **Print the list to the user before doing
anything else.** This is the transparency checkpoint: the user can
correct a mislabeled block or paste in a missing surface before any
analysis runs.

Output format: see "Output Shape" in `discovery-rules.md`.

### Disambiguation

If two unlabeled context blocks are present and the skill cannot label
them with confidence (typically Project Instructions vs Personal
Preferences), ask exactly one short question:

```
I see two context blocks I can't label with confidence. Which is which?
  A — "<first ~80 chars of block A>..."
  B — "<first ~80 chars of block B>..."
Reply: `A=personal, B=project` (or vice versa). Reply `proceed` to skip
labeling — findings will be tagged "unlabeled context block".
```

One question per run. Do not re-ask in the same conversation.

### Missing-surface case

If no surface is visible but the conversation contains decisions, emit
the "no surface visible" notice from `discovery-rules.md` and stop.
**Do not invent a file.** Do not write speculative content to
`/mnt/user-data/outputs`.

### Step 1 → Step 3 consistency check (mandatory)

Whatever surfaces you enumerate in Step 1 ARE the comparison targets in
Step 3. You cannot subsequently say "no Project Instructions exists" if
Step 1 listed a `surface: Project Instructions` row. The content quoted
in the Step 1 "first 80 chars" is the Project Instructions content —
not "the user's opening message," not "context for evaluation," not
"founding content for a not-yet-existing surface." It is the surface,
and it is the thing you compare conversation decisions against.

The failure pattern: Step 1 correctly enumerates the Project surface,
Step 2 walks the conversation, then Step 3 silently re-classifies the
Step 1 content as "in-chat opening message" and reports "no Project
Instructions found." This produces a self-contradicting report and
misses every contradiction/staleness finding the user actually invoked
the skill to surface.

If you genuinely cannot tell whether a context block is Project
Instructions vs. the user's first chat turn (e.g. the user pasted their
instructions inline as a chat message), ask one disambiguation question
before continuing — do not silently demote.

### Inverse rule: do not silently SKIP the first message either

The mirror failure of "Step 1 enumerates → Step 3 demotes" is "Step 1
never enumerates at all because the first message looked like a normal
user turn." On Claude.ai web, Project Instructions arrives unwrapped as
the first message — there is no tag to anchor on, so the model reads it
as chat and proceeds without ever listing it as a surface.

Mandatory Step 1 pass: examine the first message content of the
conversation. If it has **standing-rule shape** (recurring scope,
durable output constraints, role/situation in standing terms,
declarative prose without a one-shot deliverable — see
`discovery-rules.md` §1 "Claude.ai web: unwrapped first-message PI"),
enumerate it as `source: project-instructions`. Demote only when it is
clearly a single ad-hoc request.

If Personal Preferences was detected but no PI candidate emerges from
the first-message scan, then — and only then — emit the
"does this Project have instructions configured?" disambiguation
prompt. Asking the user is the fallback, not the substitute for the
scan.

---

## Step 1.5 — Classify each surface

Classify each surface by document type. On Claude.ai the answer is
almost always `instruction`:

- Project Instructions → `instruction` (rewrite in place).
- Personal Preferences / User style → `instruction` (rewrite in place).
- Pasted context blocks → usually `instruction`. If the block is headed
  `# Changelog` or `## [Unreleased]`, treat as `changelog` (append).
- Uploaded files → read-only; type still matters for the "re-upload an
  updated version" message but no copy-paste is emitted.

See `document-types.md` for the slim taxonomy. Ask one consolidated
question only if a pasted block is genuinely ambiguous (see
`report-format.md` "Document type" prompt). Don't re-ask within a run.

**Why this step exists on the web variant.** The single biggest failure
mode in Claude.ai testing was appending an "Update:" or "v2 scope"
section to Project Instructions instead of rewriting the stale sentence
in place. Classification binds edit strategy to surface role: every
`instruction` surface gets its stale sentence replaced, not amended.

---

## Step 2 — Extract conversation decisions

Walk this conversation top-to-bottom. For each candidate decision,
produce a structured row:

```
- subject:     "backend for v1"
  claim:       "no backend — pure client-side, browser memory only"
  turn:        [user]
  quote:       "Backend for this first demo? A: None — pure client-side, all in browser memory"
  supersedes?: "Project Instructions: 'The backend language uses Python'"
```

### Inclusion rule

**Only claims with explicit user agreement count.** Either:
- The user stated the claim directly, OR
- The assistant proposed it and the user explicitly assented in a later
  turn.

Reasonable-sounding assistant suggestions the user never confirmed do
NOT count. When in doubt, drop the row.

### Quoting rule

`quote` must be the **exact text** from the turn. Never paraphrase. The
quote is what makes a finding auditable when the user later asks "why
did you propose this change?"

### Subject normalization

Pick the shortest noun phrase another reader could match against a
surface's topic. Examples: `backend`, `rendering approach`, `v1 scope`,
`game loop architecture`. Avoid implementation detail
(`requestAnimationFrame loop`).

---

## Step 3 — Compare per surface

For each surface from Step 1, walk every decision from Step 2 and
classify the surface's stance:

| Category | When |
|---|---|
| `contradiction` | Surface asserts the opposite of the decision. |
| `stale` | Surface describes state the decision changes (renamed concept, removed dep, changed scope, **qualitative marker like "new"/"recent"/"just started" no longer fitting against a quantitative tenure stated in chat**). |
| `superseded` | Surface records a preference the decision overrides. |
| `missing-new-decision` | Surface's topic covers this subject but the decision is absent. |
| `aligned` | Surface already says what the decision says. **Not a finding.** |

### Semantic staleness — qualitative markers vs. quantitative facts

A common miss: the surface says "**new** role" / "**recently** joined"
/ "**just started** at X" / "**junior** engineer learning the
codebase", and the conversation reveals a quantitative fact that no
longer fits the marker — "**almost a year** in", "**18 months** since
I joined", "**leading the migration** now". These are `stale`, not
`missing-new-decision`. Examples:

- Surface: "My **new** role is X." Chat: "almost a year at this role"
  → `stale` (the qualifier "new" no longer fits at ~1 year).
- Surface: "I **just started** at Acme." Chat: "we shipped v2 last
  quarter" → `stale` (multi-month implication).
- Surface: "**Junior** engineer ramping up." Chat: "I'm the tech lead
  on this now" → `superseded`.

The reason this gets missed: the literal subjects ("role", "tenure",
"seniority") aren't textually identical between surface and chat, so a
shallow comparison reads them as different topics. Compare on
**implication**, not on exact subject phrasing. If a qualitative
marker on the surface no longer fits a quantitative fact in chat, flag
it.

For each non-aligned finding, record: surface label, decision row
reference, classification, exact quoted snippet from the surface,
proposed replacement.

A surface may produce multiple findings. Preserve order by position in
the surface.

### Read-only surfaces

For uploaded knowledge files (Section 3 in `discovery-rules.md`), still
classify findings, but mark each as `read-only — re-upload required to
apply` in the report. **Do not** emit a copy-paste block for these
unless the user explicitly asks to regenerate the file.

---

## Step 4 — Severity

Default severity by category:

| Category | Default severity |
|---|---|
| `contradiction` | high |
| `superseded` | high |
| `stale` | medium |
| `missing-new-decision` | medium |

Findings on Personal Preferences / User style are bumped to `high` if
the default would be lower — cross-project blast radius warrants it.

---

## Step 5 — Report and emit copy-paste

Use the template in `report-format.md`. The user-facing output is a
brief per-surface summary with two-step approval:

**Step A** — for each surface with findings, emit a short section: a
one-line intro naming the count, then numbered findings each with a
2–5 word subject and a one-line description of what changed. Internal
scaffolding (category, severity, exact line ranges, proposed
replacements) is computed but NOT shown.

**Step B** — interpret reply per surface:
- `yes` / `apply all` — approve every finding; emit the full updated
  surface text.
- `no` / `skip` — skip this surface; move to the next (if any).
- `apply N M` / `1 and 3 only` — approve listed; emit the full updated
  surface with the approved subset applied.
- `reword N to <X>` — apply with the user's revised text for that
  finding; emit the full updated surface.

Surfaces with zero findings are not mentioned at all.

(Note: `ignore` and `freeze` are not offered on Claude.ai — they require
a persisted config file the skill cannot write.)

### Per-surface copy-paste block

After approval, emit one fenced block per approved surface containing
the **full updated text**, with edits made **in place** per the
instruction-type strategy from `document-types.md`. Open with the paste
target and the iron-law line:

```
Here's the updated **Project Instructions**. Paste it into Claude.ai →
your Project → Edit instructions.
*I cannot apply it for you — Claude.ai gives me no write access to
this surface.*
```

The block content is the **full updated text of that surface** — not a
diff. Users on Claude.ai overwrite the whole instructions block;
partial diffs are harder to apply correctly than a full replacement.

Never append "Update:", "v2:", "(updated $DATE)", or "Recent decisions"
headings to an `instruction` surface. The stale sentence becomes the
new sentence; new facts go in the natural topical section.

For read-only uploaded files, skip the copy-paste block and instead
emit the flag-only notice from `report-format.md`.

### Iron law in this context

Never say "I've updated your Project instructions." Never say "applied."
Always: "Here's the block — paste it into Project settings."

### Zero findings

Emit a single line:

```
Context Update Report — <ISO timestamp>: 0 findings across <N> visible
surfaces. No drift detected.
```

---

## What is NOT in this workflow

For reference, items deliberately absent compared to the coding-agent
workflow:

- **No Step 6 apply loop.** Nothing to apply — the user pastes the block.
- **No Step 7 config persistence.** No `.contextupdate.toml` to write.
- **No `[[ignore]]` / `[[freeze]]` / `[[watch]]` queueing.** These
  require a persisted config the skill cannot write on Claude.ai.
- **No re-read step.** The surfaces don't change between Step 3 and
  Step 5 within a single chat turn.
- **No file-system probes.** No `CLAUDE.md` / `AGENTS.md` walk — those
  live on the user's local machine, not in the Claude.ai runtime.

If the user wants config persistence, ignore lists, or local
`CLAUDE.md` tracking, they should install the coding-agent variant
(`context-update`) in Claude Code, Codex, Cursor, etc. — and run this
one in Claude.ai for the Project surface.
