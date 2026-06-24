# Design rationale

Why ContextUpdate is shaped the way it is.

## Conversation-driven, not diff-driven

Most drift-detection tools in this space look at git diffs and try to
infer which documents *should* have changed to match them. That works
when:

- Every behavioral change lands as code, AND
- Every document statement is a description of code that exists.

Neither holds for reusable-context files. The most damaging drift is
preference reversal — "we don't do X anymore" — which produces no diff at
all. Likewise, decisions in plans frequently describe *intent* that is
later overridden in conversation before any code is written.

ContextUpdate therefore treats the **live conversation** as the source of
truth for recent decisions, and the context files as the durable record
that may need to catch up.

## No auto-write

The skill never modifies a watched file without explicit user approval
of every proposed edit. There are two reasons:

1. **Blast radius.** `~/.claude/CLAUDE.md` and similar personal files
   affect every project the user touches. A wrong edit is silently
   damaging across that whole surface.
2. **Trust.** Auto-applied edits to context files are how drift becomes
   corruption: an over-eager edit looks authoritative to the next session,
   which then drifts further from user intent without anyone noticing.

The gate is "every edit visible in a consolidated report before any
write." Default is one report → one `apply all` (one consent, all
diffs already shown). Per-file approval is the opt-in fallback for
users who want surgical control. Either path satisfies the iron law;
both make the user see every diff before any write happens.

The earlier per-file-only gate was relaxed after Codex testing showed
that long file lists trained users to skim-yes through 5+ prompts —
which is functionally indistinguishable from auto-apply. The
consolidated report puts every diff in front of the user once, and
asks once. That is the strongest version of the safety property the
iron law was trying to enforce.

The rationalization table exists primarily to make sure agents don't
talk themselves out of showing the report.

## Skill, not runtime code

Format is a Claude Code Skill (markdown SKILL.md + references), modeled
on `D:/Projects/superpowers`. This was chosen for three reasons:

- **Portability.** Cursor, Codex, Copilot CLI, and Gemini all recognize
  markdown skills with minor adapter changes. A runtime binary would lock
  us into Claude Code.
- **Inspectability.** Users can read exactly what the agent will do.
  There is no opaque package.
- **Token efficiency.** Lazy-loaded references mean the always-loaded
  budget per session is the description (~50 words) plus the
  session-start nudge (~80 words).

## Trigger surfaces

Two triggers, no always-on monitoring:

- `/context-update` — explicit invocation, the primary entry point.
- SessionStart-planted nudge — a single tagged reminder asking the model
  to consider running the skill before declaring a session done. Re-fired
  on auto-compact via the `compact` matcher.

Always-on per-turn monitoring was rejected because:
- It blows the always-loaded token budget on every conversation, including
  conversations that don't materially change anything.
- It conditions the agent to ignore the skill once it starts firing
  routinely.

## Why TOML

`.contextupdate.toml` is hand-edited far more often than it is generated.
TOML has comments as a first-class feature — drift-rationale notes belong
next to the entry that records them. The schema is format-agnostic; a
JSON port is mechanical.

## Word budgets

Inherited from
`D:/Projects/superpowers/skills/writing-skills/SKILL.md:213-266`:

- Always-loaded budget: ~150 words per skill (~80 for the nudge here).
- Frequently loaded body: ~500 words (SKILL.md sits near ~430).
- References: lazy-loaded; size at will.

Empirically, descriptions that summarize workflow cause agents to skip
the body. The frontmatter `description` field is therefore "Use when…"
triggers only.

## What we explicitly defer

- `[[mirror]]` blocks — orthogonal to drift detection and not needed for
  MVP correctness.
- File-arg slash command (`/context-update FILE1 FILE2 ...`) — easy add,
  not on the critical path.
- Default-off `include_user_global` — current default-on is a guess;
  revisit after feedback.
