---
name: context-update
description: Invoke when a conversation contains decisions that may need to be written back to reusable-context files (CLAUDE.md, AGENTS.md, ~/.claude/CLAUDE.md, docs/plans/*, .cursor/rules/*, personal instructions). Auto-load on surface signals — phrases like "actually", "from now on", "we don't do X anymore", "I also want", "switch to", "moving forward", "I changed my mind", "scratch that", "we're not using X anymore"; session wrap-up like "that's it for today", "I'll stop here", "wrapping up", "let me end this"; explicit asks like "update / sync / refresh / fix CLAUDE.md / AGENTS.md / the project docs"; assistant is about to scaffold code that diverges from the on-disk instructions; user self-description shifts (tenure, role, experience, team size). 中文同义触发: "其实", "从现在开始", "从今天开始", "改主意了", "对了忘了说", "这不只是 X 了", "我先到这", "回来继续", "更新 / 同步一下 CLAUDE.md". Skip on pure exploration with no decisions.
---

# Context Update

## Overview
Reusable-context files drift. A statement in CLAUDE.md from three weeks ago can be silently contradicted by today's conversation, and future sessions load the stale statement as current. This skill checks for drift on-demand and proposes — never auto-applies — edits, shaped by each file's document type.

**Core principle:** conversation is the source of truth for recent decisions; context files are the durable record. When they disagree, surface the disagreement.

**Iron Law:** every proposed edit must be visible to the user in the report before any write, and the user must explicitly approve. Default is one consolidated report → one approve-all; per-file approval is the opt-in fallback.

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
5. Present one consolidated report (`references/report-format.md`) covering every file with findings; render each diff inline as a fenced ` ```diff ` block. Ask once: **Apply all** / **Review per-file** / **Skip all**. Zero-findings files are silent. `Review per-file` drops into the per-file fallback loop.
6. Apply approved edits in order. Re-read each file immediately before writing; abort that finding if the file changed since the report. Frozen files stay gated — `Apply all` excludes them; `--override-frozen` + per-file re-confirm is the only path in.
7. If — and only if — Step 1 or 5 queued config edits, ask once before writing (via AskUserQuestion on runtimes that have it). No queue = no prompt.

**UI affordances.** When the runtime exposes `AskUserQuestion` (Claude Code / Kimi), use it for the Apply-all prompt and the Step 7 confirm. On Codex / Cursor / Copilot CLI / Claude.ai web, fall back to the typed prompt in `references/report-format.md`. The runtime's per-write approval (e.g. Codex `apply_patch`) is a safety net, not the consent surface — the user already approved every diff once in the consolidated report.

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
- Touching a `frozen=true` path without `--override-frozen` + per-file re-confirm (frozen is the one case where batch `Apply all` does NOT cover it)
- "I'll just fix the obvious one" — every edit must appear in the report and be approved before write
- Calling `Edit` before the consolidated report has been shown and approved — the report is the consent surface, not a formality
- Showing per-finding `[ y / n / edit / skip ]` prompts (deprecated — use the consolidated report's Apply-all / Review per-file / Skip-all)
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
