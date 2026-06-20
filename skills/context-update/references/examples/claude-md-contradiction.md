# Example — CLAUDE.md contradiction

A worked example showing how a single decision becomes a `contradiction`
finding.

## Setup

`CLAUDE.md` (lines 80–90):

```markdown
## Testing

We use jest for unit tests. Run with `npm test`.
Snapshot files live under `__snapshots__/`.
```

## Conversation

Turn #42, user:

> let's switch to vitest — jest is too slow on the new monorepo

Turn #43, assistant:

> Got it. I'll convert the test runner config and update package.json.

Turn #44, user:

> 👍

## Step 2 row

```
- subject:     "test runner"
  claim:       "use vitest, not jest"
  turn:        [#42, user]
  quote:       "let's switch to vitest — jest is too slow on the new monorepo"
  supersedes?: "jest"
```

## Step 3 finding

Category: `contradiction` (file asserts the opposite).
Severity: `high` (default for contradiction, plus `kind = convention`).

## Step 5 report fragment

````markdown
## Finding 1 — [high] contradiction
**File:** `CLAUDE.md`
**Category:** contradiction
**Decision source:** turn #42 — user: "let's switch to vitest — jest is too slow on the new monorepo"

**Current text (lines 82–82):**
```
We use jest for unit tests. Run with `npm test`.
```

**Proposed replacement:**
```
We use vitest for unit tests. Run with `npm test`.
```

**Rationale:** Conversation 2026-06-19 replaced jest with vitest project-wide.
**Apply?** [ y / n / edit / skip ]
````

## Notes

- The replacement keeps `npm test` unchanged because nothing in the
  conversation altered the script name. **Do not** rewrite adjacent lines
  even if they look "old."
- The snapshot-directory line stays untouched. It's adjacent but not
  contradicted.
