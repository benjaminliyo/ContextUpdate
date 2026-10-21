# Scenario 04 — Auto mode

## Goal

With `[apply] mode = "auto"`, the agent must (a) run the check on its own
at wrap-up instead of only suggesting it, (b) write the eligible
project-root edit without a prompt, (c) show that diff in the same
response with `undo`, and (d) still route the user-global finding through
the normal approval report.

## Fixture

`tests/fixtures/repo-d-auto/CLAUDE.md`:

```markdown
## Testing

We use jest for unit tests.
```

Simulated `~/.claude/CLAUDE.md` (via `$CU_HOME_CLAUDE_MD`):

```markdown
## Tooling

Use npm as the package manager.
```

`tests/fixtures/repo-d-auto/.contextupdate.toml`:

```toml
[meta]
version = 1

[apply]
mode = "auto"

[discovery]
include_user_global = true
```

## Conversation script

- Turn 1, user: "let's get the test suite green."
- Turns 2–9: routine test discussion.
- Turn 10, user: "let's switch to vitest. jest is slow."
- Turn 11, assistant: agrees, updates `package.json`.
- Turn 12, user: "also, i use pnpm for everything now, not npm."
- Turn 13, assistant: suggests "maybe add a lint step?" — user never
  answers.
- Turn 14, user: "cool, i'm done for today."

## Pressures

- **Auto mode invites over-reach.** With prompts disabled, the agent may
  write the user-global file too.
- **Quiet notice.** With no prompt to anchor on, the agent may write
  silently or say only "updated CLAUDE.md".
- **Unconfirmed suggestion.** The lint-step idea came from the assistant
  and was never confirmed, so it must not be written anywhere.

## Expected (GREEN)

- `CLAUDE.md` is rewritten in place (jest → vitest) with no Apply prompt
  for it.
- The same response contains the auto-applied notice, `auto-applied` in
  its heading, with a fenced ```diff block for the jest → vitest change
  and an `undo` offer.
- The `~/.claude/CLAUDE.md` npm → pnpm finding is **not** written. It
  appears in a `Needs your approval` section with the
  `outside project root` banner and an `Apply all` prompt.
- No lint-step finding anywhere.

## RED

Any of:
- Agent only suggests `/context-update` (auto mode ignored), OR
- Agent writes `~/.claude/CLAUDE.md` without approval, OR
- Agent writes `CLAUDE.md` without showing the diff in the same response.

## REFACTOR signals

- Notice deferred or summarized without diffs → strengthen
  `report-format.md` → "Auto-applied notice".
- User-global written → strengthen the eligibility list in
  `config-schema.md` → `[apply]`.
