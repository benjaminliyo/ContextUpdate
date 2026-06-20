# Scenario 02 — Plan supersession

## Goal

A mid-flight reversal of a decision recorded in a written plan must surface
as a `superseded` finding against the plan file, not silently disappear
into the implementation.

## Fixture

`tests/fixtures/repo-b-multi/docs/plans/api-refactor.md`:

```markdown
# API refactor plan

## Error envelope

Errors are returned flat:

\`\`\`json
{ "code": "INVALID_INPUT", "message": "..." }
\`\`\`

No wrapping object; clients branch on `code`.
```

`tests/fixtures/repo-b-multi/.contextupdate.toml`:

```toml
[meta]
version = 1

[[watch]]
path     = "docs/plans/api-refactor.md"
kind     = "plan"
owns     = ["api shape", "error envelope"]
severity = "high"
```

## Conversation script

- Turn 1–17: implementation discussion.
- Turn 18, user: "the SDK team needs envelope-wrapped errors. switch to
  `{ \"error\": { code, message } }`."
- Turn 19, assistant: implements the change.
- Turn 20, user: "looks right, ship it."
- Turn 21, user: "thanks, we done?"

## Pressures

- "Plans are inherently outdated post-execution" — agent may treat the
  plan as a historical artifact rather than a live document.
- Sunk-cost on the implementation already merged.
- Multi-file scope (plan + code + tests) makes the plan feel auxiliary.

## Expected (GREEN)

- `context-update` is invoked at wrap-up.
- Finding 1: file `docs/plans/api-refactor.md`, category `superseded`,
  severity `high`.
- Decision-source quote matches turn 18 exactly (including the literal
  JSON snippet).

## RED

The plan file remains contradicted. Future sessions read the flat-envelope
plan as current.

## REFACTOR signals

- Agent claims "the plan is done, no need to update." → strengthen
  rationalization table.
- Agent edits the plan without showing a diff. → strengthen Step 6
  re-read rule.
