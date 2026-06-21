# `.contextupdate.toml` Schema

TOML, hand-editable, lives at the repo root. Optional — the skill works with
zero config via auto-discovery. The config layers on top of (and can override)
auto-discovery.

For one-shot edits without hand-editing TOML, see
`commands/context-update-config.md` — provides `watch add/drop` and
`ignore add/drop` as a slash command (Claude Code, Codex, and any
runtime that auto-discovers `commands/`) or natural-language phrasing
on other runtimes.

## Why TOML

- Hand-edited by humans more often than by code.
- Comments are a first-class feature — drift-rationale notes belong next to
  the entry that records them.
- Aligns with the `_meta.toml` precedent used elsewhere in the ecosystem.

The schema is format-agnostic; a `.contextupdate.json` port would be
mechanical.

## Top-level

```toml
[meta]
version = 1
```

`version` is the schema version. Future incompatible changes increment it.
The skill refuses to apply edits if it sees a version it does not understand.

## `[[watch]]`

Add a file (or glob) to the watch list, or annotate an auto-discovered file
with extra metadata.

```toml
[[watch]]
path     = "docs/plans/api-refactor.md"
kind     = "plan"                  # plan|convention|memory|personal|architecture|other
owns     = ["api shape", "error envelope"]
severity = "high"                  # high|medium|low — default by category
```

Fields:
- `path` (required) — repo-relative path or glob.
- `kind` (optional) — defaults to `other`. Used for severity defaults and
  reporting.
- `owns` (optional) — list of subject keywords. A conversation decision whose
  `subject` matches an `owns` entry but is absent from the file becomes a
  `missing-new-decision` finding.
- `severity` (optional) — overrides the default severity for findings in this
  file.

## `[[ignore]]`

Drop matching paths from the watch list.

```toml
[[ignore]]
path = "docs/plans/legacy/*"
```

## `[[freeze]]`

Keep the file enumerated but never propose edits unless the invocation was
`/context-update --override-frozen`. Even then, per-file approval is still
required.

```toml
[[freeze]]
path   = "docs/legacy/*"
reason = "historical record"
```

## `[[mirror]]` *(deferred to v0.2)*

Reserved for synchronizing a section in one file from a source elsewhere.
Out of scope for MVP correctness but the block is reserved so the schema
stays forward-compatible.

```toml
[[mirror]]
target  = "CLAUDE.md#recent-decisions"
source  = "CHANGELOG.md:top-5"
markers = ["<!-- recent-decisions:start -->", "<!-- recent-decisions:end -->"]
```

## `[discovery]`

```toml
[discovery]
conversation_derived          = true
conversation_min_confidence   = "referenced"   # opened|force-loaded|referenced|mentioned
preloaded_context             = true
wellknown_probes              = true
follow_references             = true
follow_depth                  = 2
include_user_global           = true           # see note below
include_ancestors             = true
```

- `conversation_derived` — collect candidate paths from this session's tool
  calls, `@file` mentions, and prose. Highest signal for project-specific
  filenames. See `discovery-rules.md` for the filter rules.
- `conversation_min_confidence` — drop conversation-derived rows below this
  threshold. Levels: `opened` (Read/Edit/Write), `force-loaded` (`@file`),
  `referenced` (appeared in a tool result), `mentioned` (prose only).
  Default `referenced` — prose-only matches are skipped unless another
  source also picked them up.
- `preloaded_context` — include files the harness force-loads into the
  system prompt (typically `CLAUDE.md`, `AGENTS.md` at project root).
- `wellknown_probes` — turn off to suppress the slim static probe list
  entirely and rely purely on conversation-derived + preloaded + config.
- `follow_references` — turn off to limit checks to what 1–4 found.
- `follow_depth` — hops per parent. Cycle-safe via a visited set.
- `include_user_global` — include `~/.claude/CLAUDE.md` et al. Findings
  there carry an "outside project root — confirm scope" warning. (Default
  is `true` for MVP; revisit post-feedback.)
- `include_ancestors` — walk up to git root probing at each level.

## Full example

```toml
[meta]
version = 1

[[watch]]
path     = "CLAUDE.md"
kind     = "convention"
severity = "high"

[[watch]]
path     = "docs/plans/api-refactor.md"
kind     = "plan"
owns     = ["api shape", "error envelope"]
severity = "high"

[[ignore]]
path = "docs/plans/legacy/*"

[[freeze]]
path   = "docs/legacy/*"
reason = "historical record"

[discovery]
conversation_derived        = true
conversation_min_confidence = "referenced"
preloaded_context           = true
wellknown_probes            = true
follow_references           = true
follow_depth                = 2
include_user_global         = false
include_ancestors           = true
```
