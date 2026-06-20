# Worked Example — Semantic staleness (junior engineer → tech lead)

A sharp test of the **semantic staleness** rule: the surface uses a
qualitative marker (`junior engineer`, `ramping up`) and the
conversation reveals a quantitative role fact (`leading the migration`,
`tech lead`). There is **no overlapping vocabulary** between surface
and chat — no "still learning" vs "comfortable", no date arithmetic.
The only path to a finding is recognizing that the surface's qualifier
no longer fits the chat's reality.

A model that catches this example correctly is exercising the
semantic-staleness rule. A model that only does literal-subject
matching will silently miss it and report `aligned` or "no findings."

## Setup

**Watched file:** `~/.claude/CLAUDE.md` (personal instructions, user-global)

**Type classification:** `instruction`
(filename pattern: `CLAUDE.md`; content: declarative first-person rules)

**File content:**
```
# About me

I'm a junior backend engineer at Acme Corp on the payments team. Ramping
up on the codebase — be patient when I ask basic architectural questions.

I prefer concise answers and direct feedback over hedging.
```

**Conversation summary (some months later):**
- User mentions, in passing: "I'm leading the ledger-to-payments
  migration now — three engineers reporting in on it. As tech lead I'm
  trying to decide whether to land it as one PR or stage it."
- User asks a technical question on the migration design.
- User runs `/context-update`.

Note what the conversation does **not** say:
- No "I got promoted" announcement.
- No "I've been here X months" tenure marker.
- No "I'm comfortable now" claim.

The only signal is the role descriptor `tech lead` plus the action
descriptor `leading the migration, three engineers reporting in`.

## Expected Step 1.5 — Classification

```
~/.claude/CLAUDE.md
  type: instruction
  signals: filename CLAUDE.md → instruction; content has "I prefer" → instruction
  edit_strategy: rewrite-in-place
```

## Expected Step 2 — Decisions extracted

```
- subject:     "role / seniority"
  claim:       "tech lead on payments-ledger migration; three engineers reporting in"
  turn:        [user]
  quote:       "I'm leading the ledger-to-payments migration now — three engineers reporting in on it. As tech lead I'm trying to decide..."
  supersedes?: "Personal instructions: 'junior backend engineer ... ramping up on the codebase'"
```

## Expected Step 3 — Classification of stance

`stale` — not `missing-new-decision`, not `aligned`.

Rationale (internal): the surface marker `junior` is mutually exclusive
with the chat fact `tech lead`. The surface marker `ramping up` is
mutually exclusive with `three engineers reporting in`. Neither marker
is literally contradicted in chat, but each is **implication-stale**
against the role transition the chat reveals.

This is exactly the case the `stale` category was extended to cover.

## WRONG outputs

### Wrong 1 — Aligned (the silent miss)

```
No findings detected. Personal instructions are aligned with this
conversation.
```

Why wrong: the surface still says "junior, ramping up." A future
session loads that and treats the user as a junior engineer asking
basic questions — directly contradicting how they actually operate.
Silent miss, the worst failure mode.

### Wrong 2 — Appending an "Update" section

```
# About me

I'm a junior backend engineer at Acme Corp on the payments team. Ramping
up on the codebase — be patient when I ask basic architectural questions.

I prefer concise answers and direct feedback over hedging.

## Update — current role (2026-09-15)
I'm now tech lead on the payments-ledger migration.
```

Why wrong: the file now describes two contradictory roles. Every
future session has to reconcile "junior, ramping up" against "tech
lead." Instruction-type files rewrite in place; only changelogs append.

## RIGHT output (in-place rewrite)

```
# About me

I'm a backend engineer at Acme Corp on the payments team — currently
tech lead on the payments-ledger migration with three engineers
reporting in. Comfortable raising architectural questions when I think
the team's heading the wrong way.

I prefer concise answers and direct feedback over hedging.
```

Why right:
- "junior" replaced with the actual role (`tech lead on the migration`).
  The seniority marker reflects current state.
- "Ramping up... be patient with basic questions" replaced with the
  current posture (architectural pushback). The replacement lives where
  the old text lived — not appended.
- "I prefer concise answers" line untouched — surgical revision.
- A future session loads this and treats the user as a tech lead, which
  matches reality.

## User-facing report (Step 5)

```
## `~/.claude/CLAUDE.md` (1 change)
⚠ outside project root — affects every project on your account.

1. **role / seniority** — was "junior backend engineer, ramping up on
   the codebase"; this conversation has you leading the
   payments-ledger migration as tech lead. The "junior / ramping up"
   framing is stale.

Apply this to `~/.claude/CLAUDE.md`? Reply **yes** to apply, **no** to
skip, or tell me what to change (e.g. "reword to drop the migration
specifics — just say tech lead").
```

User: `yes` → model re-reads, applies the in-place rewrite, prints:

```
`~/.claude/CLAUDE.md`: 1 applied.
```

## Why this is the semantic-staleness test case

The detection only works if the comparison runs on **implication**, not
on literal subject phrasing:

- Literal subjects: `seniority` ≠ `migration ownership`. A shallow
  comparison sees two different topics and reports `missing-new-decision`
  or `aligned`.
- Implication: `junior` and `tech lead` are mutually exclusive
  descriptors of the same person. So are `ramping up` and `three
  engineers reporting in`. Implication-comparison catches it.

If you find yourself wanting to add a "still learning the codebase" line
to the surface or a "I've been here a year now" line to the chat to
make the detection easier — don't. Those are hard signals that paper
over the rule this example is meant to exercise. Keep the example
narrow.

## When the rule generalizes

Any qualitative-vs-quantitative pair where the surface holds a marker
the chat invalidates:

- Surface: "**new** hire" / Chat: "**a year** in"
- Surface: "**learning** Rust" / Chat: "**rewrote the runtime** in Rust"
- Surface: "**part of the team that built** X" / Chat: "**owner of X
  now**"
- Surface: "**considering switching to** Postgres" / Chat: "we **migrated
  to** Postgres **last quarter**"

In every case the surface marker is technically not contradicted
word-for-word; it's outpaced by the chat's later state. Flag as
`stale`, rewrite in place.
