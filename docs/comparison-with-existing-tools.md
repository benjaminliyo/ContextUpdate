# Comparison with existing tools

A non-exhaustive map of the adjacent ecosystem and why ContextUpdate
occupies a distinct niche.

## The landscape

| Tool / category | What it does | What it does *not* do |
|---|---|---|
| MCPMarket "Context Update" | Refresh tool descriptions on demand | Check *project* context files against a *conversation* |
| "CLAUDE.md Auto-Updater" | Regenerate `CLAUDE.md` from code state | Reconcile decisions, not code |
| "Context Drift Detector" | Detect drift between code and docs via diffs | Catch preference reversals (no diff) |
| DeepDocs / RepoDocs | Generate or refresh docs from code | Conversation-driven |
| Mem0 / Letta / Zep / Graphiti | Agent memory stores | Operate inside the agent, not on shared files |

## What ContextUpdate adds

- **Cross-checks reusable context files** (`CLAUDE.md`, `AGENTS.md`,
  `~/.claude/CLAUDE.md`, plans, `.cursor/rules/*.mdc`, …) against the
  decisions made in the *current* conversation.
- **No code diff required.** The most damaging drift — preference
  reversal — produces no code change. Diff-based tools miss it
  structurally.
- **Proposes per-file diffs with explicit approval.** Never auto-writes.
- **Lives at the file layer**, not inside an agent memory store. Edits
  remain auditable in git and portable across runtimes.

## What ContextUpdate is *not*

- Not a replacement for agent memory frameworks. Mem0 et al. are about
  in-agent retrieval; ContextUpdate is about durable shared files.
- Not a documentation generator. It will not write a section that wasn't
  there before unless `owns` flags a missing-new-decision *and* the user
  approves the proposed insertion.
- Not a code-diff tool. It will read code only incidentally (for example,
  to confirm a reference target exists).

## When to use each

- "Our docs are out of date relative to code." → diff-based tools.
- "Our agent should remember user facts across sessions." → memory store.
- "We discussed switching test runners three weeks ago and CLAUDE.md
  still says the old runner." → ContextUpdate.
