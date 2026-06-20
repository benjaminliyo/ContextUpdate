# Report Format

The Step 5 deliverable. The user sees a brief, per-file summary and
approves all-or-discusses; the model applies via the Edit tool per the
iron law (per-file approval before any write).

This format hides internal scaffolding (decision-extraction rows,
watch-list enumeration, severity, categories). Those run internally and
feed the proposed replacements — the user-facing output stays
conversational.

## Per-file template

For each file with one or more findings, emit a section:

````markdown
## `<path>` (<N> change<s>)
<finding-N>. **<short subject>** — <one-line description of the change>.

```diff
- <current text>
+ <proposed text>
```

<finding-N+1>. ...
````

Then the Apply? prompt — see "Apply? prompt" below for the two
delivery modes.

Rules:

- One section per file. **Files with zero findings are not mentioned.**
- `<short subject>` is the decision's normalized subject (2-5 words).
- The one-line description names *what* changed. No category names
  (`contradiction`, `stale`, …) appear in user output — they're internal.
- Each finding renders the change as a fenced ```diff block with the
  exact current snippet (`-`) and proposed replacement (`+`). For
  multi-line replacements, include enough context (typically the
  surrounding sentence or bullet) to make the change unambiguous.
  Skip the diff block only when the change is a pure structural
  insertion (no prior text to remove) — in that case show only the
  `+` lines.
- Severity is not shown.
- Finding numbers are scoped per file (each file starts at 1).

## Apply? prompt — two delivery modes

**Mode 1 — interactive (preferred on Claude Code, Kimi).** When the
runtime exposes a question tool (Claude Code / Kimi: `AskUserQuestion`),
emit the per-file section, then call the tool with one question and
four options:

```
Question: Apply <N> change<s> to `<path>`?
Options:
  1. Apply all          (Recommended)
  2. Apply some / edit  — opens a typed follow-up
  3. Skip this file
  4. Freeze this file   — keep watching but never edit (queues [[freeze]])
```

Typed follow-ups (`Apply some / edit`) accept the same shortcuts as
Mode 2 below (`apply 1 3`, `reword 2 to <X>`, etc.). `ignore` is
available as a typed shortcut from the same follow-up.

**Mode 2 — typed (fallback for runtimes without an interactive tool).**
Emit the per-file section, then append:

````markdown
Apply these to `<path>`? Reply **yes** to apply all, **no** to skip, or
tell me which to change (e.g. "1 and 3 only" or "reword 2 to <X>").
````

**Reply interpretation** (both modes):

| Reply | Action |
|---|---|
| `yes` / `apply all` / `all` | Apply every finding in this file. Re-read; abort if changed since the report. Print one-line summary. Move to next file. |
| `no` / `skip` | Skip this file. Move to next file. |
| `apply N M …` / `1 and 3 only` | Apply listed findings; skip the rest. |
| `reword N to <X>` / `change N: <X>` | Apply listed-with-revisions; confirm the revised text for each before writing. |
| `freeze` | Skip and queue `[[freeze]]` for this file (persisted in Step 7). |
| `ignore` | Skip and queue `[[ignore]]` (persisted in Step 7). |

After applying or skipping, print a single line:

```
`CLAUDE.md`: 3 applied.
`docs/plans/api-refactor.md`: 1 applied, 1 skipped.
`AGENTS.md`: skipped.
```

Then continue to the next file. **Iron law:** per-file approval before
any write. No batch "apply across all files at once" affordance.

## User-global warning

When a file is outside the project root (typically `~/.claude/CLAUDE.md`),
prepend one line to its section:

```
## `~/.claude/CLAUDE.md` (2 changes)
⚠ outside project root — affects every project on your account.
1. ...
```

## Frozen-file invocation

If the user invoked `/context-update --override-frozen`, frozen-file
findings appear in the per-file section with a single-line warning:

```
`LICENSE` is `frozen = true` (reason: "legal text"). Override active —
per-file confirmation still required.
```

## Document-type shaping

The proposed replacement for each finding is shaped by the file's type
(from Step 1.5, see `document-types.md`):

- `instruction` / `architecture` / `readme` — in-place rewrite of the
  affected sentence / bullet / section.
- `plan` — revise affected sections; if the change spans more than ~30%
  of the plan, the one-line description includes "(plan iteration)" and
  the assistant asks once before applying: *"This rewrites most of the
  plan. Proceed, or want me to scope to a single phase?"*
- `changelog` — append a new entry under the appropriate heading,
  matching existing format.
- `tasks` — add / remove / check per the file's convention.

The user-facing summary names the change, not the strategy. Strategy
is implicit in the proposed replacement that the model will apply.

## Full-file preview (large structural changes only)

For files of type `instruction`, `architecture`, `plan`, or `readme`
where the proposed change spans multiple sections, the report may emit
the full updated file text in a fenced block alongside the summary, so
the user can review the result before approving:

````markdown
Proposed full text for `<path>` (review only — apply still requires your `yes`):

```
<full updated file>
```
````

Use this sparingly — only when the change is structurally large enough
that a per-line summary won't convey the result. Single-line and
single-bullet edits never need a full-file preview.

## Step 1 watch-list emission

**Default — passive.** After enumerating, emit a single line:

```
Watching <N> file(s): `<path1>`, `<path2>`, `<path3>` — reply `edit watchlist` to change.
```

Then continue immediately to Step 1.5. Do NOT block. Most runs the
auto-discovered list is correct; interrupting for confirmation every
time creates friction that trains the user to skim past prompts.

**Interactive — only when explicitly requested or low confidence.**
Switch to the interactive editor when any of these holds:

- The user typed `edit watchlist` (or any rough equivalent like
  *"let me edit the list"*).
- The watch list is empty.
- Discovery surfaced an unusual path the agent has low confidence
  about (e.g., a file outside the project root that wasn't in
  `~/.claude/CLAUDE.md`'s usual list).

In interactive mode, prefer `AskUserQuestion` when available:

```
Question: Edit the watch list?
Options:
  1. Proceed as shown          (Recommended)
  2. Drop a row                — sub-prompt for which N
  3. Freeze a row              — sub-prompt for which N and a reason
  4. Add a path                — sub-prompt for the path
```

Typed fallback (no interactive tool, or follow-up text):

```
Reply with any of:
  drop N                      — stop watching row N (queues [[ignore]])
  freeze N "reason"           — keep watching but never edit (queues [[freeze]])
  watch PATH [k=v ...]        — add a path (queues [[watch]])
  proceed                     — continue with the list as shown
```

Multiple actions per reply are accepted (e.g. `drop 4; watch RULES.md`).
Queued edits apply to the in-memory list immediately; persist them in
Step 7.

## Step 1.5 classification-ambiguity prompt

If any file's type can't be classified confidently, prepend before any
per-file section:

```
I can't classify these files confidently:
  - `<path>` — filename suggests <type-a>, content reads like <type-b>.
  - `<path>` — ...

For each, reply with a type (`instruction` / `plan` / `architecture` /
`changelog` / `readme` / `tasks`), or `skip` to drop from this run.
```

One question covering all ambiguous files. Don't re-ask.

## Step 7 config-write prompt

**Only emitted if Step 1 or any Step-5 reply queued blocks.** If the
queue is empty, skip Step 7 entirely — no prompt, no "nothing to
persist" message. Silence is the success signal.

When the queue is non-empty, prefer `AskUserQuestion`:

```
Question: Write <N> queued change(s) to `.contextupdate.toml`?
Options:
  1. Write                  (Recommended)
  2. Show me the snippet first  — emits the TOML, then re-asks
  3. Skip                   — discard the queue, no file change
```

Typed fallback:

```
Pending config changes for `.contextupdate.toml` (<N> queued):

  + <queued block 1>
  + # queued: <source>
  ...

Write these changes to `.contextupdate.toml`? Reply **yes**, **no**, or
**edit** to supply revised TOML.
```

## Internal scaffolding (hidden from user output)

Each finding is tracked internally with full metadata for the apply
step:

- file path, type, edit strategy, exact line range, exact current snippet,
  exact proposed replacement, category, severity, decision-source turn
  + quote.

This metadata drives the per-line description in the per-file section
and the actual Edit calls. It does NOT appear in user-facing output.
The model still produces this internally — silently — because it's
what makes the apply step correct.

## Zero-findings output

When there are no findings across all watched files:

```
Checked <N> files against this conversation. No drift detected.
```

## Footer (after all files processed)

```
Done. <total-applied> change<s> applied across <files-touched> file(s).
```

Silent files (no findings) are not listed. The footer is the only
acknowledgment that the rest was checked.
