# Example — Plan supersession

A worked example showing how a conversation supersedes a written plan
without anyone updating the plan file.

## Setup

`docs/plans/api-refactor.md` (lines 60–75):

```markdown
## Error envelope

Errors are returned flat:

```json
{ "code": "INVALID_INPUT", "message": "..." }
```

No wrapping object; clients branch on `code`.
```

`.contextupdate.toml`:

```toml
[[watch]]
path     = "docs/plans/api-refactor.md"
kind     = "plan"
owns     = ["api shape", "error envelope"]
severity = "high"
```

## Conversation

Turn #18, user:

> the SDK team needs envelope-wrapped errors. switch to `{ "error": { code, message } }`.

Turn #19, assistant: implements the change.
Turn #20, user:

> looks right, ship it.

## Step 2 row

```
- subject:     "error envelope"
  claim:       "wrap errors as { error: { code, message } }"
  turn:        [#18, user]
  quote:       "the SDK team needs envelope-wrapped errors. switch to { \"error\": { code, message } }."
  supersedes?: "flat error object"
```

## Step 3 finding

Category: `superseded`.
Severity: `high` (default for superseded, plus per-watch override).

## Step 5 report fragment

````markdown
## Finding 1 — [high] superseded
**File:** `docs/plans/api-refactor.md`
**Category:** superseded
**Decision source:** turn #18 — user: "the SDK team needs envelope-wrapped errors. switch to { \"error\": { code, message } }."

**Current text (lines 62–68):**
```
Errors are returned flat:

```json
{ "code": "INVALID_INPUT", "message": "..." }
```

No wrapping object; clients branch on `code`.
```

**Proposed replacement:**
```
Errors are wrapped:

```json
{ "error": { "code": "INVALID_INPUT", "message": "..." } }
```

Clients branch on `error.code`.
```

**Rationale:** Conversation 2026-06-19 reversed the flat-envelope decision
to satisfy SDK requirements.
**Apply?** [ y / n / edit / skip ]
````

## Notes

- Plans are not "done" documents — they record intent, and intent can be
  superseded mid-flight. Don't skip plans just because the work appears
  shipped.
- Because the watch entry sets `owns = ["error envelope"]`, even if the
  plan said nothing about envelopes, an *absent* decision would have
  surfaced as `missing-new-decision`.
