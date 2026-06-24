---
name: context-update-project
description: Use when this Claude.ai conversation contains decisions that may need to be written back to the Project Instructions, Personal Preferences, or an uploaded knowledge file. Auto-load on surface signals — phrases like "actually", "from now on", "we don't do X anymore", "I also want", "switch to", "moving forward", "I changed my mind", "scratch that"; session wrap-up like "that's it for today", "I'll stop here", "wrapping up", "going to close this Project"; explicit asks like "update / sync / refresh / fix the Project instructions"; assistant is about to scaffold code that diverges from the Project text; user self-description shifts (tenure, role, experience level). 中文同义触发: "其实", "从现在开始", "从今天开始", "改主意了", "对了忘了说", "这不只是 X 了", "我先到这", "更新 / 同步一下 Project Instructions". Do NOT auto-load on pure exploration with no decisions.
---

# Context Update — Claude.ai Project

## Overview
Claude.ai Project Instructions and Personal Preferences drift. A sentence written weeks ago is silently contradicted by today's chat, and tomorrow's conversation loads the stale sentence as ground truth. This skill checks for drift on demand and emits a review-ready copy-paste block.

**Core principle:** conversation is the source of truth for recent decisions; the Project text is the durable record. When they disagree, surface it.

**Iron Law:** never claim to have applied a change. Claude.ai gives the model no write access to Project Instructions, Personal Preferences, or uploaded files. The deliverable is a block the user pastes manually.

## When to Use
- User reverses an earlier preference ("we don't do X anymore", "switch to Y")
- New scope or architectural fact emerged (cut feature, changed stack, new constraint)
- User asks to "update", "sync", "refresh", or "fix" the Project instructions
- Assistant is about to begin coding or scaffolding after planning that diverged from the Project Instructions
- User invokes `/context-update-project` or asks to "run context update"

**Do NOT use when** the chat was pure exploration with no decision, or when the sole surface is a read-only uploaded file the user hasn't asked to rewrite.

## Core Workflow
1. **Enumerate visible surfaces.** Project Instructions, Personal Preferences, uploaded files, pasted blocks. Check for EACH independently — finding one is not evidence the other is absent. Ask one disambiguation question only if two unlabeled blocks are ambiguous.
1.5. **Classify each surface** — almost always `instruction`. Pasted blocks may be `changelog`. See `references/document-types.md`.
2. **Extract decisions.** Walk the conversation. Produce `subject — claim — supersedes?` rows with **exact quoted turns**. Drop anything the user didn't explicitly agree to.
3. **Compare per surface.** Classify each stance: `contradiction | stale | superseded | missing-new-decision | aligned`. **Whatever you enumerated in Step 1 IS the comparison target** — do not re-classify Step 1 surface content as "the user's opening message" in Step 3. Compare on implication, not exact subject phrasing: qualitative markers ("new", "just started") on the surface become `stale` against quantitative facts ("almost a year") in chat.
4. **Report** per `references/report-format.md`: brief per-surface summary, two-step approval (`yes` / `no` / partial / reword). Surfaces with zero findings are not mentioned.
5. **Emit per-surface copy-paste.** After approval, one fenced block per surface with the **full updated text**, edits made **in place** (never append "Update:" / "v2:" / dated sections). Say: *"Paste this into Claude.ai → Project → Edit instructions. I cannot apply it for you."*

Zero findings → one-line confirmation. No surface visible but decisions exist → emit the missing-surface notice; do not bail.

## Red Flags — STOP
- About to say "I've updated your Project instructions" — you cannot
- Appending an "Update:" / "v2:" / "Recent decisions" section instead of rewriting in place
- Reporting one surface and stopping — PI and Personal Preferences are independent; check both
- Saying "no Project Instructions exists" after Step 1 enumerated one — Step 1 content IS the surface
- Treating "new role" + "almost a year" as aligned — qualitative markers go `stale` against quantitative tenure
- Emitting a finding against Claude's auto-memory (out of scope) instead of dropping it
- Categorizing without quoting the chat turn
- Showing only a diff instead of the full updated surface

## Rationalizations
| Excuse | Reality |
|---|---|
| "Appending is safer" | Creates a chronicle. Rewrite in place. |
| "Step 1 surface content is just the opening message" | It's the surface. Compare against it in Step 3. |
| "'New' and 'a year' are different subjects" | Compare on implication. Stale. |
| "Memory mismatch counts as a finding" | Out of scope. Drop the row. |
| "No surfaces visible — nothing to do" | Emit the missing-surface notice with detected decisions. |

See `references/detection-workflow.md`, `references/discovery-rules.md`, `references/document-types.md`, `references/report-format.md`, `references/rationalization-table.md`, `references/examples/pvz-scope-drift.md`, `references/examples/junior-to-lead-tenure-drift.md`, `references/examples/tokyo-unwrapped-pi.md`.
