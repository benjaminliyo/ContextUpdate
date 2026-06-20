# Worked Example — Semantic staleness (junior engineer → tech lead)

A sharp test of the **semantic staleness** rule on Claude.ai: the
Project Instructions surface uses a qualitative marker (`junior
engineer`, `ramping up`) and the conversation reveals a quantitative
role fact (`leading the migration`, `tech lead`). There is **no
overlapping vocabulary** between surface and chat — no "still learning"
vs "comfortable", no date arithmetic. The only path to a finding is
recognizing that the surface's qualifier no longer fits the chat's
reality.

A model that catches this example correctly is exercising the
semantic-staleness rule. A model that only does literal-subject
matching will silently miss it and report `no findings detected`.

## Setup

**Project Instructions (surface):**
```
# About me at work

I'm a junior backend engineer at Acme Corp on the payments team. Help
me ramp up — explain architectural decisions in detail, and flag where
I should push back on senior engineers vs. defer to their experience.
```

**Conversation summary:**
- User mentions, in passing: "I'm leading the ledger-to-payments
  migration now — three engineers reporting in on it. As tech lead I'm
  trying to decide whether to land it as one PR or stage it."
- User asks for help on the migration design.
- User runs `/context-update-project`.

Note what the conversation does **not** say:
- No "I got promoted" announcement.
- No "I've been at Acme X months" tenure marker.
- No "I'm no longer junior" claim.

The only signal is the role descriptor `tech lead` plus the action
descriptor `leading the migration, three engineers reporting in`.

## Expected Step 1 — Enumerate visible surfaces (internal)

```
- surface: Project Instructions
  source: project-instructions
  first 80 chars: "# About me at work\n\nI'm a junior backend engineer at Acme Corp..."
- no Personal Preferences detected
- no uploaded files
```

## Expected Step 1.5 — Classify (internal)

```
Project Instructions
  type: instruction
  signals: "Help me ramp up" imperative; "explain ... in detail" — voice/role description
  edit_strategy: rewrite-in-place
```

## Expected Step 2 — Decisions extracted (internal)

```
- subject: "role / seniority"
  claim:   "tech lead on payments-ledger migration; three engineers reporting in"
  quote:   "I'm leading the ledger-to-payments migration now — three engineers reporting in on it. As tech lead I'm trying to decide..."
  supersedes: Project Instructions: "junior backend engineer ... Help me ramp up"
```

## Expected Step 3 — Classification of stance

`stale`. The surface marker `junior` is mutually exclusive with the
chat fact `tech lead`. The surface ask `Help me ramp up` and the
implied dynamic (defer to senior engineers) is mutually exclusive with
`three engineers reporting in to me`.

Neither marker is literally contradicted in chat. Each is
**implication-stale** against the role transition the chat reveals.

## Expected Step 5 — Report (user-facing Step A)

```
I see 1 thing in this conversation that doesn't match your
**Project Instructions**:

1. **role / seniority** — was "junior backend engineer ... help me
   ramp up, flag where I should push back vs. defer to senior
   engineers"; this conversation has you leading the payments-ledger
   migration as tech lead with three engineers reporting in. The
   "junior / ramping up / defer to seniors" framing is stale.

Want me to fold this into your Project Instructions? Reply **yes** to
see the updated block, **no** to skip, or tell me what to change.
```

## Step B — User replies `yes`

In-place rewrite. The stale qualifier and the stale guidance about
deferring to senior engineers both get replaced — not appended,
not annotated with an "Update:" section.

````markdown
Here's the updated **Project Instructions**. Paste it into Claude.ai →
your Project → Edit instructions.
*I cannot apply it for you — Claude.ai gives me no write access to
this surface.*

```
# About me at work

I'm a backend engineer at Acme Corp on the payments team — currently
tech lead on the payments-ledger migration with three engineers
reporting in. Explain architectural decisions in enough detail that I
can defend the call to my team, and flag the second- and third-order
consequences I might miss as a relatively new tech lead.
```
````

Footer:
```
Done. 1 surface updated. Paste the block above into Claude.ai when
ready.
```

## WRONG outputs

### Wrong 1 — Aligned (the silent miss)

```
Checked your Project Instructions. No drift detected.
```

Why wrong: the surface still says "junior ... ramping up ... defer to
senior engineers." Every future chat in this Project loads that and
treats the user as a junior asking for hand-holding — directly
contradicting how they actually operate. Silent miss, the worst
failure mode.

### Wrong 2 — Appending an "Update" section

```
# About me at work

I'm a junior backend engineer at Acme Corp on the payments team. Help
me ramp up — explain architectural decisions in detail, and flag where
I should push back on senior engineers vs. defer to their experience.

## Update — current role
I'm now tech lead on the payments-ledger migration.
```

Why wrong: Project Instructions now describe two contradictory roles
("junior" + "tech lead"). Every future Claude.ai session loading the
Project has to reconcile them. Instruction surfaces rewrite in place;
appending is only correct for `changelog`-type pasted blocks.

## Why this is the semantic-staleness test case

The detection only works if the comparison runs on **implication**, not
on literal subject phrasing:

- Literal subjects: `seniority` ≠ `migration ownership`. A shallow
  comparison reads two different topics and reports `no findings`.
- Implication: `junior` and `tech lead` are mutually exclusive
  descriptors. So are `defer to senior engineers` and `three engineers
  reporting in to me`. Implication-comparison catches it.

If you find yourself wanting to add a "I'm no longer junior" line to
the chat or a "still learning" line to the Project Instructions to
make the detection easier — don't. Those are hard signals that paper
over the rule this example is meant to exercise. Keep the example
narrow.

## When the rule generalizes

Any qualitative-vs-quantitative pair where the surface holds a marker
the chat invalidates:

- Surface: "**new** role" / Chat: "**almost a year** at this role"
  (the real PvZ-followup test that produced this rule)
- Surface: "**learning** Rust" / Chat: "**rewrote the runtime** in Rust"
- Surface: "**considering switching to** Postgres" / Chat: "we
  **migrated to** Postgres **last quarter**"
- Surface: "**part of the team building** X" / Chat: "**owner of X
  now**"

In every case the surface marker is technically not contradicted
word-for-word; it's outpaced by the chat's later state. Flag as
`stale`, rewrite in place.
