# Worked Example — PvZ scope drift (Claude.ai)

A real-conversation fixture that demonstrates the Claude.ai workflow on
a representative pressure case. This example surfaced two failure modes
in earlier versions of the skill:

1. The skill saw "no file on disk" and bailed instead of recognizing
   the Project Instructions surface.
2. After Step 1 was fixed, the skill **appended** a "v1 scope" section
   to Project Instructions instead of revising the stale Python-backend
   sentence in place — creating a chronicle with two contradictory
   directions live at once.

This example shows the correct shape: terse summary, two-step approval,
and in-place revision per `document-types.md`.

## Setup

**Project Instructions (surface):**
```
# Plants vs Zombies Game

This project builds a web app game similar to Plants vs Zombies

## Design

- The backend language uses Python
- Use React as the frontend.
```

**Conversation summary:**
- User asked Python vs Java for backend → assistant: stick with Python,
  but you may not need a backend for v1.
- User answered three scope questions:
  - Smallest version that counts as a win? *1 lane, 1 plant, 1 zombie.*
  - Backend for this first demo? *None — pure client-side, browser memory only.*
  - Rendering approach? *Plain DOM/CSS grid.*
- User ran `/context-update-project`.

## Expected Step 1 — Enumerate (internal)

```
- surface: Project Instructions
  source: project-instructions
  editable: yes (user pastes into Project settings)
- no Personal Preferences detected
- no uploaded files
```

## Expected Step 1.5 — Classify (internal)

```
Project Instructions
  type: instruction
  signals: imperative bullets ("Use React..."); no changelog headings
  edit_strategy: rewrite-in-place
```

## Expected Step 2 — Decisions extracted (internal)

```
- subject: "backend for v1"
  claim:   "no backend — pure client-side, browser memory only"
  quote:   "None — pure client-side, all in browser memory"
  supersedes: Project Instructions: "The backend language uses Python"

- subject: "v1 scope"
  claim:   "1 lane, 1 plant, 1 zombie type"
  quote:   "1 lane, 1 plant, 1 zombie type — does it even work?"

- subject: "rendering approach"
  claim:   "plain DOM/CSS grid"
  quote:   "Plain DOM/CSS grid (simplest, fine for low entity counts)"
```

All three rows have explicit user assertions. Borderline architecture
calls without explicit assent (e.g. `requestAnimationFrame` loop)
are dropped per the inclusion rule.

## Expected Step 5 — Report (user-facing Step A)

```
I see 3 things in this conversation that don't match your
**Project Instructions**:

1. **backend for v1** — was "backend language uses Python"; you've
   decided v1 has no backend (pure client-side, browser memory).
   Python remains the planned backend for later versions.
2. **v1 scope** — new: 1 lane, 1 plant (Peashooter), 1 zombie (Basic),
   win condition = survive N waves. Project Instructions doesn't
   currently scope v1.
3. **rendering approach** — new: plain DOM/CSS grid for v1; reconsider
   canvas / Phaser / PixiJS only when entity counts exceed ~30 or
   frame budget is missed.

Want me to fold these into your Project Instructions? Reply **yes** to
see the updated block, **no** to skip, or tell me which ones to include
(e.g. "1 and 3 only" or "all but reword 2 to <X>").
```

## Step B — User replies `yes`

The skill emits the full updated surface with edits made **in place**.
Note that finding 1 replaces the stale Python-backend bullet; findings
2 and 3 extend `## Design` topically rather than appending a new
"Update:" / "v2:" section.

````markdown
Here's the updated **Project Instructions**. Paste it into Claude.ai →
your Project → Edit instructions.
*I cannot apply it for you — Claude.ai gives me no write access to
this surface.*

```
# Plants vs Zombies Game

This project builds a web app game similar to Plants vs Zombies.

## Design

- v1: no backend — pure client-side, browser memory only. Python is
  the planned backend for later versions (accounts, save games,
  leaderboards).
- React frontend. React renders output only; the game loop runs in
  `requestAnimationFrame` against a plain mutable `gameState` object
  outside React state.
- Rendering: plain DOM/CSS grid for v1. Reconsider canvas /
  Phaser / PixiJS only when entity counts exceed ~30 or the frame
  budget is missed.

## v1 scope

- 1 lane, 9 columns
- 1 plant (Peashooter), 1 zombie (Basic)
- Win: survive N waves. Lose: zombie reaches the left edge.
```
````

After emitting, the footer:

```
Done. 1 surface updated. Paste the block above into Claude.ai when
ready.
```

## What the original failing run did — and why this shape avoids it

### Failure mode A — "no file on disk → nothing to track"
The pre-redesign skill said:
```
No watched files found.
- No CLAUDE.md / AGENTS.md / GEMINI.md / .cursorrules detected
- No .contextupdate.toml config present.
```
Fixed by changing Step 1 from "probe filesystem" to "enumerate
runtime-injected surfaces." Project Instructions is a surface; disk
absence is not surface absence.

### Failure mode B — appended "v1 scope" / "Update: $DATE" section
Even after the Step 1 fix, an earlier version appended a new section to
the bottom of Project Instructions:

```
## Design
- The backend language uses Python      ← still stale
- Use React as the frontend.

## Update — v1 scope (2026-06-20)
- No backend for v1
- 1 lane, 1 plant, 1 zombie
- DOM/CSS grid
```

The Python-backend bullet remains live, contradicting the new section.
Every future Claude.ai chat now has to reconcile the two.

Fixed by Step 1.5 classification: `Project Instructions` → `instruction`
→ `rewrite-in-place`. The stale bullet becomes the new bullet; new
facts go in the natural topical section under `## Design` or a new
`## v1 scope` section that's part of the document's normal structure,
not a dated changelog entry.

### Failure mode C — per-finding `[ y / n / edit / skip ]` prompts
Earlier reports rendered each finding as a CLI-style prompt block. The
two-step format (Step A summary list → Step B single reply) is shorter
and reads as conversation, not a form.
