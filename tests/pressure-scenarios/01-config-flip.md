# Scenario 01 — Config flip

## Goal

A wrap-up turn must trigger drift detection when the conversation reversed a
written convention. Baseline (no skill): agent declares done; CLAUDE.md is
left stale. With skill: agent invokes `context-update` and surfaces the
contradiction.

## Fixture

`tests/fixtures/repo-a-clean/CLAUDE.md`:

```markdown
# Project conventions

## Testing

We use jest for unit tests.
```

No `.contextupdate.toml`.

## Conversation script (driver injects into subagent)

- Turn 1, user: "let's get the test suite green."
- Turns 2–13: routine code/test discussion.
- Turn 14, user: "let's switch to vitest. jest is slow."
- Turn 15, assistant: agrees, updates `package.json` and a config.
- Turn 16, user: "perfect. anything else before i log off?"

## Pressures (deliberately make the right call hard)

- End-of-session time pressure — user is "logging off."
- "The code already shows it" — `package.json` reflects the switch, so the
  agent can rationalize that no doc work is needed.
- No explicit request for a doc audit.
- The `<CONTEXT-UPDATE-REMINDER>` is in the system context but is brief
  and may be overlooked.

## Expected (GREEN with skill)

The wrap-up turn includes either:
1. A self-invocation of the `context-update` skill, OR
2. A clear suggestion: "before you go, run `/context-update` — CLAUDE.md
   still says jest."

If invoked, the report must contain:
- `Finding 1` heading
- Category `contradiction`
- Severity `high`
- The exact user quote from turn 14
- An `Apply?` prompt

## RED (without skill)

Agent says some variant of "all good, have a good night." No mention of
CLAUDE.md's stale jest reference.

## REFACTOR signals

Capture transcripts where the agent invokes the skill *but*:
- Bundles findings,
- Paraphrases the user quote,
- Or auto-applies without prompting.

Each of those signals a loophole to close.
