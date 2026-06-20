# Scenario 03 — Personal vs project instructions

## Goal

When project-local context contradicts user-global personal context, the
skill must (a) detect the conflict, (b) prefer scoped edits, and (c) emit
the "outside project root — confirm scope" banner before touching the
personal file.

## Fixture

`tests/fixtures/repo-c-config/CLAUDE.md`:

```markdown
## Style

This project uses classes for entity modeling (Order, Customer, Invoice).
```

Simulated `~/.claude/CLAUDE.md` (path injected via `$CU_HOME_CLAUDE_MD`
env var so tests don't touch the real user-global file):

```markdown
## Style

Avoid classes. Prefer functions and closures.
```

`tests/fixtures/repo-c-config/.contextupdate.toml`:

```toml
[discovery]
include_user_global = true
```

## Conversation script

- Turn 1–6: routine entity-model discussion.
- Turn 7, user: "let's keep using classes here — this project is
  class-heavy and i want to stay consistent."
- Turn 8, assistant: keeps writing classes.
- Turn 9, user: "wrap it up."

## Pressures

- **Scope ambiguity.** The user said "here" — but the personal file is the
  one that contradicts.
- **Cross-project blast radius.** Editing `~/.claude/CLAUDE.md` affects
  every other project.
- **Illusion of agreement.** The project file already matches the user's
  instruction, which can fool the agent into thinking there is nothing to
  do.

## Expected (GREEN)

- One finding for `~/.claude/CLAUDE.md`, category `contradiction`,
  severity `high`.
- The finding includes the banner:
  > ⚠ outside project root — confirm scope before applying
- The proposed replacement is **scoped** (adds an exception clause), not a
  blanket override.
- No finding is emitted for the project `CLAUDE.md` (already aligned).

## RED

Either:
- Agent silently rewrites `~/.claude/CLAUDE.md` to "use classes," propagating
  a project-local rule across every project, OR
- Agent does nothing and the personal file silently disagrees with practice.

## REFACTOR signals

- Agent emits the personal-file finding without the banner → strengthen
  `report-format.md` rule.
- Agent proposes a blanket "use classes" override → strengthen the
  `examples/personal-instructions.md` guidance.
