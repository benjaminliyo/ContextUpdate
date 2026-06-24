---
name: context-update
description: Use when a conversation contains decisions that may need to be written back to reusable-context files (CLAUDE.md, AGENTS.md, ~/.claude/CLAUDE.md, docs/plans/*, .cursor/rules/*, personal instructions). Auto-load on surface signals — phrases like "actually", "from now on", "we don't do X anymore", "I also want", "switch to", "moving forward", "I changed my mind", "scratch that", "we're not using X anymore"; session wrap-up like "that's it for today", "I'll stop here", "wrapping up", "let me end this"; explicit asks like "update / sync / refresh / fix CLAUDE.md / AGENTS.md / the project docs"; assistant is about to scaffold code that diverges from the on-disk instructions; user self-description shifts (tenure, role, experience, team size). 中文同义触发: "其实", "从现在开始", "从今天开始", "改主意了", "对了忘了说", "这不只是 X 了", "我先到这", "回来继续", "更新 / 同步一下 CLAUDE.md". Do NOT auto-load on pure exploration with no decisions.
---

# Context Update

## Overview
Reusable-context files drift. A statement in CLAUDE.md from three weeks ago can be silently contradicted by today's conversation, and future sessions load the stale statement as current. This skill checks for drift on-demand and proposes — never auto-applies — edits, shaped by each file's document type.

**Core principle:** conversation is the source of truth for recent decisions; context files are the durable record. When they disagree, surface the disagreement.

**Iron Law:** never modify a watched context file without explicit user "apply" decision per file.

## When to Use
- User reverses an earlier preference ("we don't do X anymore", "switch to Y")
- New architectural fact emerged (new module, removed dependency, renamed concept)
- Scope / goal / audience / quality-bar expansion — file isn't wrong, just incomplete (see `references/triggers.md`)
- Wrapping up a session in which conventions, config, or stack changed
- User runs `/context-update`

**Do NOT use when** the session was pure exploration with no decisions, when changes are purely code-level with no doc/convention implication, or when the file is frozen (`frozen=true` in config, or under `legacy/`).

## Core Workflow
1. Enumerate watched files via `references/discovery-rules.md` — primarily files the conversation touched, plus preloaded context, slim probes, config, and references. Print as a one-line passive summary and proceed; only enter interactive editing (AskUserQuestion) when the user types `edit watchlist` or the list is empty / low-confidence.
1.5. Classify each file by document type (`instruction | plan | architecture | changelog | readme | tasks`) via `references/document-types.md`. Type determines whether to rewrite in place, revise affected sections, or append. Ask once on ambiguity.
2. Extract conversation decisions as `subject — claim — supersedes?`, with the exact turn quoted.
3. For each watched file, read fresh and classify each decision's stance: contradiction, stale, superseded, missing-new-decision, aligned.
4. Categorize and assign severity (`high|medium|low`) — internal, not shown to user.
5. Present the per-file report (`references/report-format.md`) with two-step approval per file: summary list, then `yes` / `no` / partial / reword. Files with zero findings are not mentioned.
6. Apply approved edits. Re-read before writing; abort if file changed. The proposed text was shaped by the file's type — apply as written.
7. If — and only if — Step 1 or 5 queued config edits, ask once before writing (via AskUserQuestion on runtimes that have it). No queue = no prompt.

**UI affordances.** When the runtime exposes an interactive question tool (Claude Code / Kimi: `AskUserQuestion`), use it for the per-file Apply? prompt and the Step 7 confirm, and render each proposed change as a fenced ` ```diff ` block. On runtimes without it, fall back to the typed markdown options in `references/report-format.md`.

## Quick Reference
| Conversation signal | Likely category |
|---|---|
| "we're not using X anymore" | superseded |
| "actually, prefer Y" | contradiction |
| "move to module Z" | stale |
| "from now on, always..." | missing-new-decision |
| file says "junior / new / just started"; chat reveals "tech lead / a year in / shipped X" | stale (semantic) |

## Red Flags — STOP
- Appending to a non-changelog file (creates a chronicle instead of current state)
- Categorizing without quoting the contradicting turn
- Touching a `frozen=true` path
- "I'll just fix the obvious one" — every file needs explicit approval
- Showing per-finding `[ y / n / edit / skip ]` prompts (deprecated — use per-file two-step)
- Treating qualitative markers ("junior", "new", "just started") in the file as aligned with quantitative facts in chat — that's `stale`, not `aligned`

## Rationalizations
| Excuse | Reality |
|---|---|
| "Appending is safer" | Only changelogs append. Other types must rewrite in place — a chronicle forces every future session to reconcile. |
| "User obviously wants this" | Obvious ≠ consented. Ask. |
| "Auto-apply is faster" | Auto-apply is how drift becomes corruption. |
| "Conversation implied it" | Implication ≠ decision. Quote the turn or skip. |
| "Re-reading is wasteful" | Files change between turns. Re-read. |
| "Different subjects → not a finding" | Compare on implication. Qualitative markers go `stale` against quantitative facts. |

See `references/detection-workflow.md`, `references/discovery-rules.md`, `references/document-types.md`, `references/config-schema.md`, `references/report-format.md`, `references/triggers.md`, `references/rationalization-table.md`.
