# Example — Personal vs project instructions

A worked example showing how the skill handles a contradiction between
`~/.claude/CLAUDE.md` (personal, cross-project) and the project's own
`CLAUDE.md`.

## Setup

`~/.claude/CLAUDE.md`:

```markdown
## Style

Avoid classes. Prefer functions and closures.
```

`CLAUDE.md` (project root):

```markdown
## Style

This project uses classes for entity modeling (Order, Customer, Invoice).
```

`.contextupdate.toml`:

```toml
[discovery]
include_user_global = true
```

## Conversation

Turn #7, user:

> let's keep using classes here — this project is class-heavy and i want to stay consistent.

Turn #8, assistant: continues writing class-based code.

## Step 2 row

```
- subject:     "coding style: classes"
  claim:       "keep using classes in this project"
  turn:        [#7, user]
  quote:       "let's keep using classes here — this project is class-heavy and i want to stay consistent."
  supersedes?: null
```

## Step 3 findings

Two findings:

1. `~/.claude/CLAUDE.md` — `contradiction` (personal file says "avoid
   classes"; user just confirmed classes for this project).
2. `CLAUDE.md` — `aligned` (no finding emitted).

## Step 5 consolidated report fragment

````markdown
# Context update — 1 change across 1 file

## `~/.claude/CLAUDE.md` (1 change)
⚠ outside project root — affects every project on your account.
1. **coding style: classes** — add a per-project exception for class-based projects (do NOT delete the default rule).

```diff
- Avoid classes. Prefer functions and closures.
+ Default: avoid classes. Prefer functions and closures.
+ Exception: in projects that explicitly opt into class-based modeling,
+ follow the project's style.
```

Apply all 1 change? Reply **apply all**, **review**, or **skip all**.
Note: 1 file (`~/.claude/CLAUDE.md`) is outside this project and affects
every project on your account.
````

## Notes

- Internal scaffolding (category `contradiction`, severity `high`,
  decision-source quote from turn #7) is computed but NEVER appears in
  user-facing output.
- This is the canonical case for **scoped edits, not blanket overrides**:
  the user's preference is project-local, not personal-global. The proposed
  replacement adds an exception clause rather than deleting the original
  rule.
- Because the path is outside the project root, the warning banner is
  **required** and the out-of-project note appears in the Apply prompt.
- If the user replies `review` and then asks for a `reword 1 to <X>`,
  accept their replacement verbatim. Do not "improve" it.
- An alternative valid outcome is `skip all` (or `skip <path>`) — the user
  may decide their personal file should stay neutral. Skipping is not
  failure.
