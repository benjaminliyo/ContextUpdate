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

## Step 5 report fragment

````markdown
## Finding 1 — [high] contradiction
> ⚠ outside project root — confirm scope before applying
> changes here affect every project, not just this one

**File:** `~/.claude/CLAUDE.md`
**Category:** contradiction
**Decision source:** turn #7 — user: "let's keep using classes here — this project is class-heavy and i want to stay consistent."

**Current text (lines 12–13):**
```
Avoid classes. Prefer functions and closures.
```

**Proposed replacement:**
```
Default: avoid classes. Prefer functions and closures.
Exception: in projects that explicitly opt into class-based modeling,
follow the project's style.
```

**Rationale:** The user reaffirmed classes for *this* project. The personal
instruction file should not be flipped wholesale; it should acknowledge the
per-project exception.
**Apply?** [ y / n / edit / skip ]
````

## Notes

- This is the canonical case for **scoped edits, not blanket overrides**:
  the user's preference is project-local, not personal-global. The proposed
  replacement adds an exception clause rather than deleting the original
  rule.
- Because the path is outside the project root, the banner is **required**.
- If the user replies `edit`, accept their replacement verbatim and apply
  it. Do not "improve" it.
- An alternative valid outcome is `skip` — the user may decide their
  personal file should stay neutral. Skipping is not failure.
