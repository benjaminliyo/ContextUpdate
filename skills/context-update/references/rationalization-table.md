# Rationalization Table (Extended)

The five rows in the SKILL.md body cover the most common shortcuts. This
file collects the longer tail observed during pressure testing, organized
by the phase of the workflow where they appear.

## Discovery phase

| Excuse | Reality |
|---|---|
| "I already know the repo's files." | Reads change between sessions and across worktrees. Run discovery. |
| "User wouldn't care about that file." | The watch list is shown in Step 1 specifically so the user can prune. Don't prune for them. |
| "`~/.claude/CLAUDE.md` is mine to manage." | The user invoked the skill in *this* project — flag the cross-project blast radius. |

## Decision-extraction phase

| Excuse | Reality |
|---|---|
| "The user clearly meant X." | Implication isn't agreement. Quote a turn or drop the row. |
| "I'll paraphrase to keep the report short." | Paraphrase is where misrepresentation hides. Quote exactly. |
| "We discussed it earlier; that's enough." | Discussion ≠ decision. Look for explicit agreement. |
| "The assistant suggested it; the user didn't object." | Silence is not consent. Drop the row. |

## Classification phase (Step 1.5)

| Excuse | Reality |
|---|---|
| "Filename ends in `.md` — that's enough, I'll treat it like CLAUDE.md." | Filename alone is weak. Check headings, length, voice. A `docs/plans/*.md` is a plan, not an instruction. |
| "Type doesn't matter — the proposed edit is the same either way." | It isn't. Instructions rewrite in place; changelogs append; plans revise affected sections. Same input, different outputs. |
| "When in doubt, classify as `instruction` — safest default." | Wrong default. Misclassifying a changelog as instruction means rewriting history; misclassifying a plan means flattening phase structure. Ask the consolidated question. |
| "I'll skip classification when there's only one file." | One file is exactly when getting the strategy right matters most. Run it. |
| "Heading `## Update (2024-01-15)` means changelog." | Not necessarily — could be a half-corrupted instruction file someone appended to. Cross-check the rest of the document. |

## Edit-strategy phase

| Excuse | Reality |
|---|---|
| "Appending to CLAUDE.md is safer — I won't lose the old info." | Appending creates a chronicle. Future sessions then have to reconcile two contradictory statements. Rewrite in place. |
| "An 'Update: $DATE' section makes the change auditable." | Auditability lives in git history, not in the file body. The file should read as current state. |
| "v2 / v3 headings let me preserve the user's earlier preference." | The user reversed the earlier preference. Preserving it as a still-live section reintroduces drift the moment the next session loads it. |
| "The change is big — better to add a 'Recent decisions' block than rewrite." | Big changes are exactly when rewriting matters. A 'Recent decisions' block becomes the new permanent prelude on every future read. |
| "Plan files are append-only by convention." | Plan files iterate. Revise the affected phase in place. Only `changelog` and `tasks` files append. |
| "The decision touches three sections — too risky to revise all three. I'll add a note." | A note creates four sections to reconcile. Revise all three. Plan iteration is normal. |

## Comparison phase

| Excuse | Reality |
|---|---|
| "I read this file two turns ago — it's fine." | Re-read. Files change. |
| "The contradiction is in a code block — doesn't count." | Code blocks in convention files express intent. They count. |
| "It's a small wording difference." | Wording is the surface where conventions live. Flag it. |
| "The file uses the old name but everyone knows the new one." | Future sessions don't. Update the file. |
| "'Junior engineer' on the file and 'tech lead' in chat are different subjects — `missing-new-decision`, not a contradiction." | Compare on implication, not on exact subject phrasing. A qualitative marker ("junior", "new", "just started", "learning") becomes `stale` when chat reveals a quantitative fact that no longer fits it. |
| "Tenure / seniority is just background context — no file owns it." | If the file uses qualitative markers ("junior", "ramping up", "just started"), the file owns the marker implicitly. New facts that invalidate the marker are findings, not free-floating context. |

## Reporting phase

| Excuse | Reality |
|---|---|
| "I'll combine these two findings; they're related." | Two subjects = two findings, numbered separately. The user can still approve both with `yes`. |
| "Severity will help the user prioritize." | Severity is internal scaffolding. The two-step format hides it. |
| "I'll show the exact diff so the user can review precisely." | The per-file section shows one-line descriptions only. Detailed diffs / proposed replacements stay internal until approval. |
| "The quote is long; I'll truncate." | Truncate and you've stopped quoting. Quote stays internal anyway — the user-facing line is the description, not the snippet. |
| "I'll show per-finding `[ y / n / edit / skip ]` prompts — clearer." | Deprecated. Use the per-file two-step (`yes` / `no` / partial / reword). Per-finding bracket prompts created CLI-style noise in testing. |

## Apply phase

| Excuse | Reality |
|---|---|
| "`approve-high` means all highs including frozen." | Frozen still requires per-file confirmation. |
| "The file barely changed; the diff should still apply." | If the file changed since the report, abort and re-report. |
| "I'll fix that adjacent typo while I'm here." | Out of scope. Surgical edits only. |
| "User said 'apply all' — that covers everything." | Confirm 'all' explicitly; still gate frozen files. |

## Config persistence (Step 1 & Step 7)

| Excuse | Reality |
|---|---|
| "User said `drop 3` — I'll just remove it in memory; no need to persist." | Without persistence, the next session re-discovers it and re-asks. Queue the `[[ignore]]`. |
| "Multiple drops can be one config write without showing the diff." | One write, one confirmation, but the diff MUST be shown. |
| "User said `proceed` so they don't care about config." | `proceed` means "stop adding edits," not "discard the queue." Still emit Step 7. |
| "I'll auto-create `.contextupdate.toml` so the user doesn't have to confirm." | Iron law applies to config files too. Show the new-file diff; ask once. |
| "`ignore` and `freeze` mean the same thing — pick whichever." | They don't. See `report-format.md`. `ignore` drops from the watch list; `freeze` keeps it visible but ungates editing. Ask the user if unclear. |
| "Reasoning out a `reason` field for `freeze` is overkill." | The reason is what makes a future maintainer trust the freeze. Pass through what the user said; don't invent one. |

## Meta

| Excuse | Reality |
|---|---|
| "This skill is for big drifts; small ones aren't worth a report." | Small drifts compound. Emit the report; the user decides. |
| "No findings — silent return is cleaner." | Emit the one-line zero-findings confirmation. The user needs to know the check ran. |
| "The workflow is overkill for one decision." | The workflow IS the skill. Skipping steps reproduces the drift it's meant to catch. |
