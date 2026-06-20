# Report Format — Claude.ai

The Step 5 deliverable. The user sees a brief summary of proposed
changes per surface, approves all-or-discusses, then receives the full
updated text to paste into Claude.ai's settings panels.

This format hides internal scaffolding (decision-extraction rows,
surface enumeration, severity, categories, finding metadata). Those
run internally — the user-facing output stays conversational.

## Per-surface template

For each surface with one or more findings, emit a section:

````markdown
I see <N> thing<s> in this conversation that don't match your
**<surface name>**:

<finding-N>. **<short subject>** — <one-line description>.
<finding-N+1>. ...

Want me to fold these into your <surface name>? Reply **yes** to see
the updated block, **no** to skip, or tell me which ones to include
(e.g. "1 and 3 only" or "all but reword 2 to <X>").
````

Rules:

- One section per surface. **Surfaces with zero findings are not mentioned.**
- `<surface name>` is the user-friendly label: "Project Instructions",
  "Personal Preferences", "pasted block", or the uploaded file's name.
- `<short subject>` is the decision's normalized subject (2-5 words).
- The one-line description names *what* changed.
- No severity, category, or finding-metadata appears in user output.
- Finding numbers scoped per surface (each starts at 1).

## Personal Preferences warning

When the surface is Personal Preferences, prepend one line to the
section:

```
⚠ Personal Preferences (User style) — changes here affect every
Project on your account, not just this one.
```

## Read-only uploaded files

Findings on uploaded knowledge files are flag-only — no copy-paste
block:

```
Your uploaded file `pvz-design.md` is out of sync with this
conversation on: backend scope, v1 entity counts. It's read-only;
re-upload an updated version if you want to keep using it as Project
knowledge.
```

## Two-step interaction per surface

**Step A** — emit the per-surface section. Wait for reply.

**Step B** — interpret the reply:

| Reply | Action |
|---|---|
| `yes` / `apply all` / `all` | Approve every finding. Emit the full updated surface text in a fenced block. |
| `no` / `skip` | Skip this surface. Move to next (if any). |
| `apply N M …` / `1 and 3 only` | Approve listed findings; the others are skipped. Emit the full updated surface with the approved subset applied. |
| `reword N to <X>` / `change N: <X>` | Apply the user's revised text for that finding. Emit the full updated surface. |

## Per-surface copy-paste block (after approval)

After approval (yes / partial / reworded), emit:

````markdown
Here's the updated **<surface name>**. Paste it into <location>.
*I cannot apply it for you — Claude.ai gives me no write access to
this surface.*

```
<full updated surface text, with edits made in-place per the
instruction-type strategy from document-types.md>
```
````

Where `<location>` is:

- Project Instructions → "Claude.ai → your Project → Edit instructions"
- Personal Preferences → "Claude.ai → Settings → Profile → personal preferences"
- Pasted block → "back into wherever you keep this file"

Rules:

- Show the **full** updated surface text. Not a diff.
- Edits are made **in-place** per the instruction-type strategy: stale
  sentences become the new sentence, new facts go in the natural topical
  section. Never append "Update:", "v2:", "(updated $DATE)", or
  "Recent decisions" headings.
- Preserve untouched text verbatim — same headings, same whitespace,
  same bullet style.
- Never abbreviate with `... (rest unchanged) ...`.
- Keep total length similar to the original. Replacing 2 bullets with 3
  is fine; replacing 2 bullets with 12 means tighten before emitting.

## Iron-law phrasing rules

Every copy-paste block must include "I cannot apply it for you" or
equivalent.

Acceptable:
- "Paste this into …"
- "Copy the block below into …"
- "I cannot apply it for you — paste it manually."

Unacceptable:
- "I've updated your Project instructions."
- "Project instructions have been updated."
- "Done — applied to your Project."

## Disambiguation prompts (only when needed)

**Surface labeling** — if Step 1 detected two unlabeled blocks:

```
I see two context blocks I can't label with confidence. Which is which?
  A — "<first ~80 chars of block A>..."
  B — "<first ~80 chars of block B>..."
Reply `A=personal, B=project` (or vice versa), or `proceed` to skip
labeling — findings will be tagged "unlabeled context block".
```

**Document type** — if Step 1.5 left a pasted block ambiguous:

```
I can't classify the pasted block confidently. Treat as `instruction`
(rewrite in place) or `changelog` (append entries)?
```

One question per ambiguous item. Don't re-ask in the same run.

## Missing-surface output

If Step 1 found no surfaces but Step 2 found decisions:

```
No reusable-context surface visible in this chat.

Decisions detected:
  - <subject 1> — <one-line summary>
  - <subject 2> — <one-line summary>

To track these, paste your Project Instructions (or the file you'd like
checked) into the chat and re-run.
```

## Zero-findings output

When surfaces ARE visible but there are no findings:

```
Checked your <Project Instructions / Personal Preferences / both>.
No drift detected.
```

## Footer (after all surfaces processed)

```
Done. <surfaces-touched> surface(s) updated. Paste the block(s) above
into Claude.ai when ready.
```

Silent surfaces (no findings) are not listed.
