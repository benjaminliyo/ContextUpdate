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

## Step 3 finding (internal)

Category: `contradiction` (file asserts the opposite).
Severity: `high` (default for contradiction, plus `kind = convention`).

These are internal scaffolding and MUST NOT appear in user-facing output.

## Step 5 consolidated report fragment

````markdown
# Context update — 1 change across 1 file

## `CLAUDE.md` (1 change)
1. **test runner** — switch jest to vitest in the Testing section.

```diff
- We use jest for unit tests. Run with `npm test`.
+ We use vitest for unit tests. Run with `npm test`.
```

Apply all 1 change? Reply **apply all** to write, **review** to step
through file-by-file, **skip all** to write nothing.
````

## Notes

- The replacement keeps `npm test` unchanged because nothing in the
  conversation altered the script name. **Do not** rewrite adjacent lines
  even if they look "old."
- The snapshot-directory line stays untouched. It's adjacent but not
  contradicted.
