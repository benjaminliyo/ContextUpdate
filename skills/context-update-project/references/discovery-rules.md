# Discovery Rules — Claude.ai

How the skill assembles the list of "visible surfaces" to compare against
the current conversation. Performed in Step 1 of the Core Workflow.

Claude.ai has no filesystem the skill can probe and no git root to walk.
There are no well-known probe paths, no `.contextupdate.toml`, no
reference-following across files on disk. The only context the skill can
inspect is whatever the runtime has already put into the conversation.

## Surfaces, in priority order

1. **Project Instructions** — the editable text block attached to the
   active Claude.ai Project. Arrives in one of **two equally common
   forms** — check both, do not stop at form (a):
   - **(a) Wrapped** — inside a system-context block (e.g. `<claudeMd>`,
     `<project_instructions>`, `<userInstructions>`, or similar
     runtime-defined wrapper). Easy to anchor on a tag.
   - **(b) Unwrapped first message** — **Claude.ai web's default
     delivery**. PI arrives as the **first message content of the
     conversation** with no wrapper tag, visually indistinguishable
     from a user turn. There is no tag to anchor on; you must apply
     the standing-rule shape test in §1 below to recognize it.
   Highest priority because it is the durable record that future
   sessions will load. **Absence of (a) is NOT absence of PI** — always
   run the shape test for (b) before concluding "no Project
   Instructions configured."
2. **Personal Preferences / User style** — the cross-project text block
   attached to the user's account. May appear under labels like "User
   style", "Personal preferences", "About me", or similar. Always flag
   findings here with the "outside this project" warning.
3. **Uploaded knowledge files** — files attached to the Project or
   uploaded into the conversation. Treated as **read-only** by default.
   The skill may flag drift but must not propose in-place rewrites unless
   the user explicitly asks to regenerate the file.
4. **Pasted context blocks** — markdown the user pasted directly into a
   chat turn that is clearly a reusable-context document (e.g. they
   pasted their `CLAUDE.md` body for review).

Each surface is tagged with its origin and (when relevant) a short
reason. The merged list is printed to the user before Step 2 runs.

## Look for surfaces INDEPENDENTLY — do not stop after finding one

Project Instructions and Personal Preferences are **separate surfaces
that almost always coexist**. Finding one is not evidence the other is
absent. The most common discovery failure observed in testing was:

1. Model sees the Personal Preferences block (e.g. "Be a ruthless
   mentor…") and labels it correctly.
2. Model implicitly assumes that's the only context block.
3. Project Instructions ("My new role is an assistant actuarial
   analyst…") is silently skipped even though it was injected into the
   same system context.

Run the detection rules for **every** surface section below on every
invocation. Do not short-circuit. If only one surface seems present,
explicitly ask whether the other is configured — the cost of one
sentence ("I see Personal Preferences but no Project Instructions —
does this Project have instructions configured?") is far lower than
silently missing a surface.

### Block-shape disambiguation

When two unlabeled blocks are visible, classify by **what they own**,
not by length or position:

- A block describing **the user** (tone, voice, working style, mentor
  persona, output preferences) → Personal Preferences.
- A block describing **the work / domain / role / scope** (job title,
  employer, stack, conventions, "help me with X") → Project
  Instructions.
- A block doing both → ask. One block rarely owns both; if it appears
  to, the user has probably duplicated content across surfaces.

---

## 1. Project Instructions

### Detection
The runtime usually injects Project Instructions as a labeled context
block before the first user turn. Look for:

- A `<claudeMd>` / `<project_instructions>` / `<system_context>` /
  `<userInstructions>` / `<projectInstructions>` tag in the system
  message or earliest assistant context.
- A "Codebase and user instructions are shown below" preamble.
- A "Contents of …" block whose path resembles a Project text body.
- Free text describing the work the user wants help with — job role,
  project domain, stack, scope, "help me with X questions". Even
  without a wrapper tag, this content is Project Instructions if it
  describes the work rather than the user's communication preferences.

#### Claude.ai web: unwrapped first-message PI (default case)

On Claude.ai web, **Project Instructions has no wrapper tag**. It
arrives as the **first message content** of the conversation,
visually indistinguishable from a regular user turn. Personal
Preferences gets a recognizable surface marker and is detected
normally; PI does not.

Default rule: **treat the first message content as a Project
Instructions candidate** and enumerate it as `source:
project-instructions` in Step 1. Demote it to "user's opening turn"
only if it is clearly a single ad-hoc request — one focused ask, no
durable rules.

Standing-rule shape (= it IS Project Instructions, even though it
looks like chat):

- Sets ongoing output constraints ("keep answers under 600 words",
  "每天分成上午/下午/晚上", "always include cost per person").
- Describes recurring scope or a category of work ("help me plan
  Tokyo trips", "review SQL migrations I send you"), not a one-off
  ("plan tomorrow's meeting agenda").
- States user identity/situation in standing terms ("this is my
  first time in Japan", "I don't speak Japanese", "I'm a junior
  actuary").
- Multiple paragraphs of declarative prose with no specific
  deliverable ask, OR a deliverable ask plus standing rules attached.

One-off chat turn (= NOT Project Instructions):

- Single focused request with a concrete deliverable
  ("write a function that parses this CSV").
- Time-bound to this session ("for tomorrow's meeting", "today",
  "right now").
- References specific files/topics rather than setting global rules.

If Personal Preferences IS visible but no obvious Project Instructions
wrapper is present, **the first message is your PI candidate** — apply
the standing-rule shape test above. Do not conclude "no Project
Instructions" without running that test on the first message.

**Red flag for the copy-paste step:** the revised PI block must contain
ONLY the PI you enumerated in Step 1. Never include the user's actual
chat turns (the one-shot ask, follow-up questions, decisions made later
in conversation) in the body of the revised PI surface. Those are
inputs to Step 2 (decisions), not surface content. If a chat decision
changes a PI rule, the new RULE replaces the stale rule in-place — the
chat quote does not get pasted in verbatim.

### Editable?
**Yes — by the user, manually.** The model cannot write to this surface.
Findings here are the primary deliverable. Tag as
`source: project-instructions`.

### What it owns
Whatever the Project text says it owns. Common topics: stack choices,
scope, conventions, definitions, architectural facts. Treat every
declarative sentence as ownership of its subject.

---

## 2. Personal Preferences / User style

### Detection
A second context block, usually shorter than Project Instructions, often
labeled "User style", "About me", "Personal preferences", or referenced
inside the same `<claudeMd>` envelope under a separate sub-heading.

If two unlabeled blocks are present and ambiguous, ask one
disambiguation question (see `report-format.md` → "Claude.ai
disambiguation"). One question per run; do not re-ask.

### Editable?
**Yes — by the user, manually, in account settings.** Tag as
`source: personal-preferences`. **Always** apply the user-global warning
banner (see `report-format.md`) to findings here — edits affect every
Project, not just this one.

### What it owns
Tone, format preferences, workflow rules, cross-project conventions.

---

## 3. Uploaded knowledge files

### Detection
Files visible in the conversation as attachments or referenced in tool
results that the model can read but not modify. Includes Project
knowledge files (attached at Project level) and one-off uploads in this
chat.

### Editable?
**No — read-only.** The skill may flag drift here (and should, when the
file's content materially contradicts a chat decision), but the report
entry must say `read-only — re-upload required to apply`. Do not emit a
copy-paste block for these unless the user explicitly asks to regenerate
the file.

Tag as `source: uploaded-file (read-only)`.

---

## 4. Pasted context blocks

### Detection
The user pasted a recognizable reusable-context document directly into a
chat turn — e.g. they pasted their `CLAUDE.md` body for review. Heuristic:
a fenced or unfenced markdown block in a user turn whose content
declares conventions / stack / scope and whose first lines resemble a
project README or instruction file.

### Editable?
**Indirectly.** The pasted text isn't a surface the user can edit
in-place from chat — they edit it in whichever tool owns the source. The
copy-paste block tells them where to put the updated version (typically
back into their Project Instructions, an external `CLAUDE.md` file on
their machine, or wherever they pasted it from).

Tag as `source: pasted-block`. If the user labeled it (e.g.
"here's my CLAUDE.md"), record the label.

---

## Missing-surface handling

If Step 1 finds zero candidate surfaces but the conversation contains
substantive decisions (Step 2 produces non-empty rows), do **not** bail
silently. Emit:

```
No reusable-context surface visible in this chat. If you have Project
Instructions or a CLAUDE.md you'd like checked, paste them in and re-run.
Decisions detected this session: <count> — they will not be tracked
anywhere until a surface is provided.
```

Then stop. Do not invent a surface. Do not write speculative files to
`/mnt/user-data/outputs`.

---

## Output Shape (Step 1 deliverable)

Print a flat list to the user before Step 2:

```
- surface: Project Instructions
  source: project-instructions
  editable: yes (user pastes into Project settings)
  first 80 chars: "# Plants vs Zombies Game\n\nThis project builds a web app game similar..."

- surface: Personal Preferences
  source: personal-preferences
  editable: yes (user pastes into account settings)
  warning: outside this project — changes affect every Project
  first 80 chars: "I prefer concise answers and direct feedback over hedging..."

- surface: pvz-design-notes.md
  source: uploaded-file (read-only)
  editable: no — re-upload required to apply
  size: ~2.3 KB
```

After the user has seen this list, proceed to Step 2 (extract decisions).
