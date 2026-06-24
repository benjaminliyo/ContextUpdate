# Report Format

The Step 5 deliverable. The user sees one consolidated report — every
file, every finding, every diff inline — and approves all-at-once,
drops to per-file review, or skips everything. The model then applies
via the Edit tool. The iron law is that **every proposed edit must be
visible in the report before any write**; one batched `yes` after seeing
all diffs satisfies that.

This format hides internal scaffolding (decision-extraction rows,
watch-list enumeration, severity, categories). Those run internally and
feed the proposed replacements — the user-facing output stays
conversational.

## Consolidated report (default)

After Step 4, emit a single message containing one section per file
with findings, in this order:

````markdown
# Context update — <N> change<s> across <M> file<s>

## `<path-1>` (<N1> change<s>)
1. **<short subject>** — <one-line description of the change>.

```diff
- <current text>
+ <proposed text>
```

2. ...

## `<path-2>` (<N2> change<s>)
1. ...

Apply all? [see Apply? prompt below]
````

Rules:

- One section per file with findings. **Files with zero findings are
  not mentioned.**
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
- Frozen files are NOT included in the consolidated report unless
  `/context-update --override-frozen` was used. See "Frozen-file
  invocation" below.

## Apply? prompt — two delivery modes

**Mode 1 — interactive (preferred on Claude Code, Kimi).** When the
runtime exposes a question tool (Claude Code / Kimi: `AskUserQuestion`),
emit the consolidated report, then call the tool with one question and
four options:

```
Question: Apply <N> change<s> across <M> file<s>?
Options:
  1. Apply all              (Recommended)
  2. Review per-file        — drops into the per-file loop below
  3. Skip all
  4. Apply with edits       — typed follow-up: "apply <path>: 1 3; reword <path>: 2 to <X>; skip <path>"
```

**Mode 2 — typed (fallback for Codex, Cursor, Copilot CLI, Claude.ai
web).** Emit the consolidated report, then append:

````markdown
Apply all <N> change<s>? Reply **apply all** to write everything,
**review** to step through file-by-file, **skip all** to write nothing,
or tell me what to change (e.g. "apply <path>: 1 3; reword <path>:
2 to <X>; skip <path>").
````

On Codex, after `apply all`, the skill makes Edit calls back-to-back.
Codex's native `apply_patch` approval may surface each write — that's a
runtime safety net, not the primary consent gate. The user already
approved every diff by typing `apply all` after the consolidated
report.

**Reply interpretation (consolidated mode):**

| Reply | Action |
|---|---|
| `apply all` / `yes` / `all` | Apply every finding across every file in order. Re-read each file before its write; abort that finding if it changed since the report. Print the per-file results footer. |
| `skip all` / `no` | Write nothing. Print "Skipped — N changes not applied." Move to Step 7 if config edits queued. |
| `review` / `review per-file` | Drop into the per-file fallback loop (see below). |
| `apply <path>: N M …` | Apply listed findings in that file; skip the rest. Repeat segments separated by `;` to mix across files. |
| `reword <path>: N to <X>` | Apply listed finding(s) with the user's revised text; confirm the revised text before writing. |
| `skip <path>` | Drop that file from the apply set. |
| `freeze <path>` | Skip that file and queue `[[freeze]]` (persisted in Step 7). |
| `ignore <path>` | Skip and queue `[[ignore]]` (persisted in Step 7). |

After all approved writes complete, print the footer:

```
`CLAUDE.md`: 3 applied.
`docs/plans/api-refactor.md`: 1 applied, 1 skipped (file changed since report; re-run).
`AGENTS.md`: skipped.
```

## Per-file fallback (when user replies `review`)

Drop into a per-file loop. For each file in the consolidated report,
re-emit just that file's section (the diffs are already visible above,
but re-emit the heading so the prompt has clear context), then ask:

**Interactive (`AskUserQuestion`):**

```
Question: Apply <N> change<s> to `<path>`?
Options:
  1. Apply all in this file (Recommended)
  2. Apply some / edit      — typed follow-up
  3. Skip this file
  4. Freeze this file       — keep watching but never edit (queues [[freeze]])
```

**Typed:**

````markdown
Apply these to `<path>`? Reply **yes** to apply all in this file,
**no** to skip, or tell me which to change (e.g. "1 and 3 only" or
"reword 2 to <X>").
````

| Reply | Action |
|---|---|
| `yes` / `apply all` / `all` | Apply every finding in this file. Re-read; abort if changed. Print one-line summary. Move to next file. |
| `no` / `skip` | Skip this file. Move to next file. |
| `apply N M …` / `1 and 3 only` | Apply listed findings; skip the rest. |
| `reword N to <X>` / `change N: <X>` | Apply listed-with-revisions; confirm the revised text for each before writing. |
| `freeze` | Skip and queue `[[freeze]]` for this file (persisted in Step 7). |
| `ignore` | Skip and queue `[[ignore]]` (persisted in Step 7). |

The per-file loop exists because some users want surgical control on
some runs. It is not the default and is not the iron-law gate — the
consolidated report is.

## User-global warning

When a file is outside the project root (typically `~/.claude/CLAUDE.md`),
prepend one line to its section in the consolidated report:

```
## `~/.claude/CLAUDE.md` (2 changes)
⚠ outside project root — affects every project on your account.
1. ...
```

If the consolidated set contains any out-of-project files, the
Apply-all prompt adds one trailing line:

```
Note: 1 file (`~/.claude/CLAUDE.md`) is outside this project and affects every project on your account.
```

The user can still `apply all`; the warning just makes the blast radius
visible.

## Frozen-file invocation

Frozen files are excluded from the consolidated report by default. If
the user invoked `/context-update --override-frozen`, frozen-file
findings appear in their own section at the end with a one-line warning,
and `apply all` does NOT cover them — each frozen file requires its
own per-file re-confirmation:

```
## `LICENSE` (1 change) — FROZEN
⚠ `frozen = true` (reason: "legal text"). Override active —
this file requires per-file confirmation; `apply all` excludes it.
1. ...
```

After the regular Apply-all completes (or is skipped), the skill
prompts per frozen file individually.

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
the full updated file text in a fenced block alongside that file's
section, so the user can review the result before approving:

````markdown
Proposed full text for `<path>` (review only — apply still requires your `apply all` or `yes`):

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

If any file's type can't be classified confidently, prepend before the
consolidated report:

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

This metadata drives the per-line description in the consolidated
report and the actual Edit calls. It does NOT appear in user-facing
output. The model still produces this internally — silently — because
it's what makes the apply step correct.

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
