# Rationalization Table — Claude.ai (Extended)

The five rows in the SKILL.md body cover the most common shortcuts. This
file collects the longer tail observed during Claude.ai pressure tests,
organized by workflow phase. Rationalizations marked **(web-specific)**
do not appear in the coding-agent variant.

## Discovery phase

| Excuse | Reality |
|---|---|
| "No file on disk → nothing to track." **(web-specific)** | The Project Instructions block IS the surface. Disk-absence is not surface-absence. |
| "I can probe for `CLAUDE.md` like in Claude Code." **(web-specific)** | There is no filesystem here. The only surfaces are what the runtime injected into context. |
| "The user didn't paste anything — they must not have a project text." | If a Project Instructions block is in your system context, it's there. Check before assuming. |
| "I'll skip the disambiguation question to save a turn." | One question is cheaper than misattributing a finding to the wrong surface. |
| "I see Personal Preferences — that's the surface." **(web-specific, real failure)** | Personal Preferences and Project Instructions are independent surfaces and almost always coexist. Re-scan for a work-describing block (role, domain, stack, scope) before concluding "no Project Instructions." |
| "There's no `<projectInstructions>` wrapper, so it's not there." **(web-specific)** | Runtimes inject the Project surface under varying wrappers (`<claudeMd>`, `<userInstructions>`, sometimes inline). Classify by content (describes the work? → Project) not by tag name. |
| "The first message is the user's opening turn, not Project Instructions." **(web-specific, real failure)** | On Claude.ai web, Project Instructions ships unwrapped as the first message — that IS the surface. Apply the standing-rule shape test (recurring scope, durable constraints, role in standing terms, no one-shot deliverable). Demote to "user's opening turn" only when it's clearly a single ad-hoc request. |
| "If both surfaces were present, they'd be obviously labeled." | They often aren't. Test by content: who/what does the block describe? User → Personal; work → Project. |
| "Personal Preferences was detected, so I'll just ask the user whether PI is configured." **(web-specific)** | Asking is the fallback, not the substitute for scanning. Run the first-message standing-rule test first; only ask if that test produces no PI candidate. |

## Decision-extraction phase

| Excuse | Reality |
|---|---|
| "The user clearly meant X." | Implication isn't agreement. Quote a turn or drop the row. |
| "I'll paraphrase to keep the report short." | Paraphrase is where misrepresentation hides. Quote exactly. |
| "The assistant suggested it; the user didn't object." | Silence is not consent. Drop the row. |
| "The user agreed but qualified it; I'll record the unqualified version." | Record the qualifier. The qualifier IS the decision. |
| "We discussed it earlier; that's enough." | Discussion ≠ decision. Look for explicit agreement. |

## Classification phase (Step 1.5)

| Excuse | Reality |
|---|---|
| "All Claude.ai surfaces are instructions — classification is wasted work." | Almost always true, which is why the slim taxonomy ships only `instruction` and `changelog`. The work is checking the pasted-block edge case, not picking from six types. |
| "The pasted block starts with `# Changelog` but the user wants me to update conventions in it." **(web-specific)** | If the heading reads changelog, ask once. Don't silently rewrite history with a convention. |
| "When unclear, default to `instruction` — safest." | Wrong default on Claude.ai too. Misclassifying a pasted changelog as instruction means rewriting past entries; ask the single consolidated question. |

## Edit-strategy phase

| Excuse | Reality |
|---|---|
| "Adding a `## Update — 2024-11-12` section preserves both old and new." **(web-specific)** | It also forces every future Claude.ai session loading the Project to reconcile the two. Rewrite the stale sentence in place. |
| "A v2 / v3 / `## Recent decisions` heading makes the change visible." **(web-specific)** | Visibility is for changelogs. Project Instructions are read as current state on every chat start. Make the body current. |
| "The change is big — I'll append a 'scope revision' section instead of revising in place." **(web-specific — this is the PvZ failure mode)** | Big changes are exactly when in-place revision matters. Two contradictory scope sections produce the next round of drift. |
| "The user wants both the old and the new direction recorded." | Quote them on that. If they didn't say so, they want the new direction. Old context belongs in chat history, not in Project Instructions. |
| "I'll keep the old sentence and add a parenthetical." | Parentheticals stack. Two iterations later the file is unreadable. Replace, don't pile on. |
| "Personal Preferences are short — I'll just append a line." **(web-specific)** | Short surfaces are exactly where appending shows worst. Find the topical section; replace in place. |

## Comparison phase

| Excuse | Reality |
|---|---|
| "The Project text uses old wording but everyone knows the new one." | Future sessions don't. Surface the drift. |
| "The contradiction is in a code block — doesn't count." | Code blocks in Project Instructions express intent. They count. |
| "It's a small wording difference." | Wording is the surface where conventions live. Flag it. |
| "The uploaded file contradicts the chat — I'll rewrite it." | Uploaded files are read-only. Flag drift; don't propose a rewrite unless the user asks. |
| "Step 1 listed Project Instructions, but in Step 3 I'll treat its content as the user's opening message and report 'no PI configured'." **(web-specific, real failure)** | That's a self-contradicting report. The Step 1 surface content IS the surface. If you can't tell PI from a pasted-inline first turn, ask one disambiguation question — do not silently demote. |
| "'New role' on the surface and 'almost a year' in chat are different subjects, so it's a `missing-new-decision`, not a contradiction." **(real failure)** | Compare on implication, not on exact subject phrasing. A qualitative marker ("new", "just started", "recently") becomes `stale` when chat reveals a quantitative fact that no longer fits it. |
| "The title in chat differs from Claude's auto-memory — I'll flag it." | Auto-memory is out of scope for this skill. If the PI surface already matches the chat title, there is no finding. Drop the row. |
| "Tenure is just a free-floating fact; no surface owns it." | If the surface uses tenure markers ("new", "junior", "just started"), the surface owns tenure implicitly. New tenure facts that invalidate the marker are findings, not free-floating context. |

## Reporting phase

| Excuse | Reality |
|---|---|
| "I'll combine these two findings; they're related." | Two subjects = two findings, numbered separately. The user can still approve both with `yes`. |
| "I'll show only the diff — the user can figure out the rest." | The user pastes the full surface. Show the full updated text after approval. |
| "Severity will help the user prioritize." | Severity is internal scaffolding. The two-step format hides it. |
| "I'll show per-finding `[ y / n / edit / skip ]` prompts — clearer." **(web-specific)** | Deprecated. Use the per-surface two-step (`yes` / `no` / partial / reword). Bracket prompts read as CLI noise in chat. |
| "The quote is long; I'll truncate." | Truncate and you've stopped quoting. Quote stays internal anyway — the user-facing line is the description. |
| "Personal Preferences findings don't need the warning banner — the user knows." **(web-specific)** | Always emit the banner. Cross-project blast radius matters. |

## Apply phase (web-specific)

The "apply phase" on Claude.ai is the user pasting the block. The
model's job ends at emitting the deliverable.

| Excuse | Reality |
|---|---|
| "I'll write the updated text to `/mnt/user-data/outputs/CLAUDE.md` so the user has a copy." **(web-specific)** | That's a phantom file. The user has to download it, then manually paste — same as if you'd shown the block inline, minus a step. Just show the block. |
| "I'll say 'I've updated your Project instructions' since the user will paste it." **(web-specific)** | The model did not update anything. The Iron Law forbids this phrasing even when the user is about to do it themselves. |
| "An artifact would be nicer than a code block." | Artifacts are fine when the user asks. By default emit the inline block — it's the lowest-friction paste path. |
| "The user said `apply all` — I'll auto-apply." **(web-specific)** | "Apply all" on Claude.ai means "include all in the copy-paste block." It does not mean — and cannot mean — that the model wrote to Project settings. |
| "Multi-step copy-paste is annoying — I'll merge surfaces into one block." | Project Instructions and Personal Preferences live in different settings panels. Merging them breaks the paste path. |

## Missing-surface case (web-specific)

| Excuse | Reality |
|---|---|
| "No surfaces → I'll bail silently." | Decisions in the chat still matter. Emit the missing-surface notice with the decision list, and ask the user to paste their Project text. |
| "I'll create a new `CLAUDE.md` for them." | You don't know what's already in their Project. Creating one risks overwriting work. Ask first. |
| "I'll just answer the meta-question and skip the skill." | If the user invoked `/context-update`, they want the workflow. Run it, even if the deliverable is "no surface visible — paste your Project text." |

## Meta

| Excuse | Reality |
|---|---|
| "This skill is for big drifts; small ones aren't worth a report." | Small drifts compound. Emit the report; the user decides. |
| "The workflow is overkill for one decision." | The workflow IS the skill. Skipping steps reproduces the drift it's meant to catch. |
| "No findings — silent return is cleaner." | Emit the one-line zero-findings confirmation. The user needs to know the check ran. |
| "Claude.ai users won't read a long report." | Length isn't the problem — friction in pasting is. A long report with a clean copy-paste block at the end beats a short report with no deliverable. |
