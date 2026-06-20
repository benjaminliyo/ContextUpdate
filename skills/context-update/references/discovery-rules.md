# Discovery Rules

How the skill assembles the list of "watched files" to compare against the
current conversation. Performed in Step 1 of the Core Workflow.

## Sources, in priority order

1. **Conversation-derived** — file paths the agent or user actually
   touched in this session. Highest signal for project-specific filenames
   the skill can't predict (`RULES.md`, `docs/decisions/*`,
   `.agent/instructions.md`, anything).
2. **Preloaded context** — files the harness force-loaded into the system
   prompt or pre-message context (typically `CLAUDE.md`, `AGENTS.md`
   at the project root). Covers the "auto-loaded at session start but
   never re-opened" case that conversation-derived alone misses.
3. **Well-known probes** — a slim list of truly universal names.
4. **Config `[[watch]]`** — explicit user overrides.
5. **Reference-following** — outbound links from anything 1–4 found.

Each discovered path is tagged with its `source` and (when relevant) a
short reason. The merged list is printed to the user before Step 2 runs.

---

## 1. Conversation-derived

Walk this conversation top-to-bottom and collect candidate paths from:

### Signals

- **Tool calls** — every `Read`, `Edit`, `Write`, `NotebookEdit` (and
  equivalents on other harnesses) carries a path argument. Highest
  confidence — the file was provably accessed.
- **`@file` mentions** — Claude Code force-loads. Treat as "opened."
- **Tool results** — file paths that appear in the *output* of tool calls
  (`Glob`, `Grep` results, directory listings). Medium confidence — found,
  not necessarily used.
- **Prose mentions** — path-like tokens in user or assistant turns:
  `[text](path.md)`, `` `path/to/foo.md` ``, bare `path/to/foo.md`. Low
  confidence — may be incidental.

### Filter (candidate → watched)

Keep only paths that satisfy ALL of:

- Resolves to an existing file (probe at enumeration time).
- Extension in `{.md, .mdc, .markdown, .rules, .txt}` OR basename in
  `{.cursorrules, .clinerules, .windsurfrules, .contextupdate.toml}`.
- Not under any of: `node_modules/`, `dist/`, `build/`, `target/`,
  `.next/`, `.venv/`, `vendor/`, `coverage/`, `.git/`.
- Path is inside the git root, OR `include_user_global = true` and the
  path is under a user-global root (`~/.claude/`, `~/.codex/`,
  `~/.gemini/`, `~/.agents/`).

### Confidence → severity hint

| Signal | Default treatment |
|---|---|
| `Read`/`Edit`/`Write` tool call | source: `conversation-derived (opened)` — full severity per `detection-workflow.md`. |
| `@file` force-load | source: `conversation-derived (force-loaded)` — full severity. |
| Tool result mention only | source: `conversation-derived (referenced)` — severity floor of `medium`. |
| Prose mention only | source: `conversation-derived (mentioned)` — severity floor of `low`. Skipped entirely unless the path is also matched by another source. |

A path matched by multiple signals takes the highest-confidence row.

### Compaction caveat

The skill can only see what's currently in its context window. If a
conversation has been auto-compacted, earlier tool calls may be lost.
For this reason:

- The SessionStart nudge re-fires on `compact` (already configured in
  `hooks/hooks.json`) so the skill is offered before more drift accrues.
- Step 1 prints a one-line note when it detects the context was compacted
  (heuristic: missing message ids, or compaction summary tokens in the
  transcript). The user is warned that conversation-derived discovery may
  be partial.

---

## 2. Preloaded context

Files the harness loads before the first user turn. The agent didn't
"open" them via a tool call, but they're part of every session's working
context — exactly the files whose drift bites future sessions.

Treat as watched if present:

- Project root, walking up to git root: `CLAUDE.md`, `AGENTS.md`.
- The plugin-defined system reminders themselves are NOT watched (they
  belong to the runtime, not the project).

Tag as `source: preloaded-context`. Severity follows the normal defaults
in `detection-workflow.md` (typically high, since these are
convention files).

---

## 3. Well-known probes (slim list)

Existence checks, walked from cwd up to git root when
`include_ancestors = true`. Kept deliberately short — anything
project-specific should come from conversation-derived discovery or
config.

### Project-level
- `CLAUDE.md`
- `AGENTS.md`
- `GEMINI.md`
- `.cursor/rules/*.mdc`
- `.cursorrules`
- `.clinerules`
- `.windsurfrules`
- `.github/copilot-instructions.md`

### User-global (only when `include_user_global = true`)
- `~/.claude/CLAUDE.md`
- `~/.claude/agents/*.md`
- `~/.codex/AGENTS.md`

Tag as `source: auto-wellknown`.

**Removed from the probe list** (compared to earlier drafts): `docs/plans/*.md`,
`plans/*.md`, `.claude/memories/*.md`, `docs/conventions/*.md`,
`CONVENTIONS.md`, `ARCHITECTURE.md`. These were guesses at project
convention; conversation-derived discovery picks them up when they exist
and are actually used, and `[[watch]]` covers them when they aren't.

---

## 4. Config `[[watch]]`

Explicit user paths from `.contextupdate.toml`. Always included, even if
absent from conversation. Tag as `source: config`.

See `config-schema.md`.

---

## 5. Reference-following

After loading every file discovered by 1–4, scan for outbound references
and recurse:

- Markdown links: `[anything](relative/or/abs/path.md)`
- Inline mentions: `(see|refs?:)\s+\S+\.md`
- Force-load markers: `@path/to/file.md`
- TOML/YAML block fields: `path\s*=\s*["']([^"']+\.md)["']`

Defaults:
- `follow_references = true`
- `follow_depth = 2`
- Maintain a visited set keyed by absolute path to break cycles.
- Drop references resolving outside the git root unless allowed by
  `include_user_global`.

Tag follow-up discoveries as `source: auto-referenced (from <parent>)`.

---

## Merging order

For each candidate path collected across sources:

1. Apply `[[ignore]]` globs from config → drop.
2. Apply `[[freeze]]` globs from config → keep, mark `frozen=true`,
   record `reason`.
3. If multiple sources discovered the same path, keep the highest-priority
   row (1 > 2 > 3 > 4 > 5) but list all sources in the merged row's
   `also_via` field.
4. Apply matching `[[watch]]` entry's `kind`, `owns`, `severity`
   metadata.

---

## Output Shape (Step 1 deliverable)

Print a flat list to the user before Step 2. Each row records *why* the
path is watched so the user can prune intelligently:

```
- path: CLAUDE.md
  kind: convention
  source: preloaded-context
  also_via: [auto-wellknown, conversation-derived (opened)]
  frozen: false

- path: docs/decisions/2026-06-error-envelope.md
  kind: other
  source: conversation-derived (opened)
  reason: Read tool call at turn #18
  frozen: false

- path: docs/plans/api-refactor.md
  kind: plan
  source: config
  also_via: [auto-referenced (from CLAUDE.md)]
  frozen: false

- path: RULES.md
  kind: other
  source: conversation-derived (referenced)
  reason: appeared in Grep result at turn #6
  frozen: false
  confidence: medium

- path: docs/legacy/initial-design.md
  kind: other
  source: auto-wellknown
  frozen: true
  reason: historical record

- path: ~/.claude/CLAUDE.md
  kind: personal
  source: auto-wellknown
  also_via: [conversation-derived (opened)]
  frozen: false
  warning: outside project root — confirm scope before applying

- note: context was auto-compacted earlier this session;
        conversation-derived discovery may be partial.
```

After the user has seen this list, proceed to Step 2 (extract decisions).
