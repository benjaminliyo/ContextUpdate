# Changelog

All notable changes to this plugin will be documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed
- `context-update-project` now detects Project Instructions when
  Claude.ai web delivers it as the **unwrapped first message** of the
  conversation. Previous behaviour: the skill keyed off wrapper tags
  (`<projectInstructions>`, `<claudeMd>`) and the "Codebase and user
  instructions are shown below" preamble; on Claude.ai web there is
  no wrapper and no preamble, so the first message was read as a
  regular user chat turn and PI was silently skipped — even when the
  skill could literally quote PI text, it attributed the quote to
  "you said this this time" and asked "does this Project have
  instructions configured?". Worse, durable PI rules (e.g. "回答控制
  在 600 字以内") leaked into false Personal Preferences findings
  because they looked like new ad-hoc constraints from the chat.
  - `references/discovery-rules.md` §1: added the "Claude.ai web:
    unwrapped first-message PI (default case)" subsection with a
    standing-rule shape test — durable output constraints, recurring
    scope, standing-terms identity, declarative prose without a
    one-shot deliverable → PI; single focused time-bound ask → chat
    turn. Plus a red flag: the revised PI block must contain ONLY the
    PI enumerated in Step 1, never the user's actual chat turns.
  - `references/detection-workflow.md` Step 1: added the inverse
    demotion rule — mandatory first-message scan, enumerate as PI if
    standing-rule shape, fall back to the "is PI configured?"
    disambiguation prompt only if no PI candidate emerges.
  - `references/rationalization-table.md` discovery phase: two new
    rows covering "first message is just chat" and "asking
    substitutes for scanning."
  - `references/examples/tokyo-unwrapped-pi.md`: canonical fixture
    mirroring `D:/Projects/demo1/claude-web-demo/`, including the
    standing-rule shape check, expected Step 1/2/5 output, and the
    RED transcript from the failing run. Linked from
    `SKILL.md:53`.
  - Verified working on Claude.ai web with the demo1 Tokyo fixture
    after rebuilding and re-uploading the slim zip.
- `description:` field on both `skills/context-update/SKILL.md`
  (full) and `skills/context-update-project/SKILL.md` (Claude.ai
  Web) rewritten to align with Claude.ai's skill-loading heuristic.
  Previous descriptions phrased every Use-when as a self-referential
  semantic judgment — "may contradict the Project Instructions",
  "reverses a preference", "supersedes one already in the Project
  text", "diverged from the Project Instructions" — which asked the
  loading subsystem to perform the exact deep PI-vs-conversation
  comparison that IS the skill's own workflow. Result: auto-trigger
  was unreliable on Claude.ai Web (no SessionStart hook to fall back
  on) and brittle on any code-agent runtime where the nudge hook
  fails silently. New descriptions enumerate surface anchors lifted
  from `hooks/nudge.txt` ("actually", "from now on", "we don't do X
  anymore", "I also want", "switch to", "moving forward", "I changed
  my mind", "scratch that"), session wrap-up signals ("that's it for
  today", "I'll stop here", "wrapping up", "let me end this" /
  "going to close this Project"), explicit asks ("update / sync /
  refresh / fix the Project instructions / CLAUDE.md / AGENTS.md /
  the project docs"), assistant-about-to-scaffold-diverging-code,
  and user-self-description-shift. Each description also includes a
  short row of Chinese-language synonyms (其实 / 从现在开始 /
  从今天开始 / 改主意了 / 对了忘了说 / 这不只是 X 了 / 我先到这 /
  更新一下) for native-language audiences. Both descriptions close
  with "Do NOT auto-load on pure exploration with no decisions" to
  bound greediness. Sibling `context-update-config` description was
  audited and left untouched — it already enumerates literal trigger
  phrases ("watch CHANGELOG.md", "ignore docs/legacy/**", etc.),
  which is the load-heuristic-friendly pattern the workhorse skills
  had been missing. Discovered while designing a Chinese demo: the
  skill never auto-triggered mid-conversation even with obvious
  anchors like "其实改主意了" / "从现在开始" in the user turn — root
  cause was the chicken-and-egg in the description itself, not
  anything in the hook chain or the SKILL body.
- `dist/context-update-project-claudeai-0.1.2.zip` is now stale
  relative to source. Rebuild via
  `powershell -ExecutionPolicy Bypass -File scripts\build-claudeai-project-zip.ps1`
  before re-uploading to Claude.ai. No version bump applied here —
  release-cut decision deferred.
- Codex auto wrap-up nudge now reaches both Codex/Windows and the
  bash-based Codex installs (macOS/Linux, untested) via **two
  SessionStart entries** in `hooks/hooks-codex.json`. The first
  entry is the v0.1.2-verified
  `powershell -NoProfile -ExecutionPolicy Bypass -File
  hooks/session-end-nudge.ps1`; the second is
  `bash hooks/session-end-nudge`. On each platform one interpreter
  is present and that hook injects the nudge; the other fails with
  exit code 1 and Codex surfaces it as "SessionStart hook (failed)"
  alongside the successful one — cosmetic only, the reminder still
  reaches the model.
- Verified on Codex Desktop / Windows (maintainer's build, 2026-06-22):
  the PowerShell entry injects the literal
  `<CONTEXT-UPDATE-REMINDER>` block; the bash entry fails (most
  likely because Codex's marketplace sync converts the script's LF
  endings to CRLF in its cache, which is exactly the bug v0.1.2's
  CHANGELOG documents — bash chokes on parsing — and is also why we
  use PowerShell on Windows in the first place). Codex/macOS+Linux
  not maintainer-verified; reports welcome.
- Walked back every intermediate Codex/Windows experiment that
  failed during this debugging round: inline
  `powershell ... || bash ...` chain (Codex/Windows doesn't shell-interpret
  the command field); cmd/bash polyglot launcher
  `hooks/codex-launcher.cmd` (emitted correct stdout in every
  isolated test but Codex Desktop completed the hook without
  injecting); dual-key JSON via custom escaper in
  `session-end-nudge.ps1` (no longer present — `.ps1` is byte-identical
  to v0.1.2 `ConvertTo-Json -Compress`); `UserPromptSubmit` hook
  entry (no longer present). The methodical bisection from the
  verified-working v0.1.2 baseline isolated that dual-entry hooks
  are fine on Codex/Windows; whichever of the other changes was the
  regression has been removed.
- `hooks/session-end-nudge.ps1`, `hooks/session-end-nudge`, and
  `tests/verify-codex-surface.ps1` are byte-identical to commit
  `e5fa156` (Release v0.1.2). Only `hooks/hooks-codex.json` changes
  vs v0.1.2 — to add the second bash SessionStart entry.
- `commands/context-update-config.md` invocation modes rewritten to
  stop implying the slash command works on Codex/others. Slash command
  is Claude Code only; every other agent gets identical functionality
  via the sibling `context-update-config` skill or natural language.
- `AGENTS.md` rewritten as a discovery shim that references CLAUDE.md
  as canonical. The previous "intentionally identical" claim was never
  true.
- `docs/installing-per-runtime.md` Claude.ai section now documents both
  the slim `context-update-project` and the full `context-update`
  builder scripts, with output zip names. Troubleshooting line for
  "skill doesn't appear" now lists both top-level entries.

### Changed
- `context-update-nudge` skill removed from `.codex-plugin/plugin.json`
  and `.cursor-plugin/plugin.json`. Both runtimes deliver the nudge
  via SessionStart hook, so exposing the always-loaded skill was dead
  manifest weight that contradicted the skill's own "do NOT load on
  runtimes with hooks" frontmatter. Kimi remains the only manifest
  that lists it (Kimi has no `additionalContext` injection surface).
- `README.md` opener reframed as "cross-runtime agent skill — verified
  on Claude Code and Codex Desktop (Windows), packaged for Claude.ai,
  Cursor, Copilot CLI, Gemini CLI, Kimi Code, OpenCode, and Pi", and
  the Claude.ai paragraph now states explicitly that the slim variant
  is the recommended Claude.ai path while the full zip is a
  cross-runtime compatibility option.

## [0.1.2] — 2026-06-22

### Fixed
- Codex auto wrap-up nudge now works on Codex Desktop / Windows.
  Three layered bugs were diagnosed on 2026-06-22:
  1. Output JSON shape — Codex requires the nested
     `hookSpecificOutput.additionalContext` form. The bash script
     was emitting the flat shape because Codex sets `PLUGIN_ROOT`
     (not `CLAUDE_PLUGIN_ROOT`), and the elif only matched the
     latter.
  2. Git Bash PATH — `run-hook.cmd` invokes `bash.exe` directly
     without sourcing the login profile, so `/usr/bin` (dirname,
     cat, date, …) wasn't on PATH and the script died on line 12.
  3. CRLF line endings — Codex's marketplace sync on Windows
     converted the bash script's LF endings to CRLF in its cache,
     which broke bash's parsing of the elif chain (verified by
     byte-comparing repo source vs cache).
  Rather than keep stacking fixes on the bash path, the Codex hook
  now uses native PowerShell (`hooks/session-end-nudge.ps1`).
  PowerShell sidesteps every one of those failure modes. Verified
  by inspecting a fresh Codex Desktop session's transcript — the
  `<CONTEXT-UPDATE-REMINDER>` block arrives in the agent's context
  on session start.
- `.gitattributes` pins line endings: shell scripts and text
  formats to LF, batch/cmd/ps1 files to CRLF. Defensive against
  future autocrlf surprises across runtimes.

### Added
- `hooks/session-end-nudge.ps1` — PowerShell SessionStart hook for
  Codex on Windows. Uses `[System.IO.File]::ReadAllText` to avoid
  PowerShell 5.1's wrapped-string serialization quirk, forces
  UTF-8 stdout without BOM, emits compact single-line nested-shape
  JSON.

### Known limitation
- Codex on Linux/macOS — the hook command hard-codes `powershell`,
  which isn't standard on those platforms. Auto-nudge is
  unsupported there. The skill still works via native discovery
  (invoke by message). Deferred: a polyglot launcher that
  dispatches PowerShell on Windows and bash on Unix.

## [0.1.1] — 2026-06-21

### Added
- `skills/context-update-config/SKILL.md` — sibling skill for one-shot
  `.contextupdate.toml` edits, so skill-only runtimes (Codex, Cursor,
  Kimi, OpenCode, Pi) can expose `/context-update-config`. Claude Code
  keeps the existing `commands/context-update-config.md` as a thin
  alias.
- `tests/verify-codex-surface.ps1` — regression guard for the sibling
  skill + Codex manifest version bump.

### Changed
- `.codex-plugin/`, `.cursor-plugin/`, `.kimi-plugin/` switched the
  `skills` field from `"./skills/"` wildcard to explicit arrays. This
  excludes `context-update-project` (web-only) from code-agent
  distributions. `.claude-plugin/plugin.json` adds the new skill to
  its existing explicit list.
- All manifests bumped `0.1.0` → `0.1.1`.
- `CLAUDE.md` corrected: Codex/Cursor/Kimi/OpenCode/Pi enumerate slash
  commands from `skills/`, not `commands/*.md`. Sibling skill recorded
  as a layout invariant.

### Known limitations
- `.opencode/plugins/context-update.js` and
  `.pi/extensions/context-update.ts` register `skills/` wholesale via
  code, so `context-update-project` (web-only) still leaks into those
  runtimes. Deferred.

## [0.1.0] — 2026-06-20

### Added
- Initial MVP scaffold.
- `skills/context-update/` with SKILL.md and references for discovery,
  detection workflow, config schema, report format, and rationalization
  table.
- `/context-update` slash command.
- SessionStart-planted self-reminder (`hooks/session-end-nudge`) and
  Windows-compatible `run-hook.cmd` shim.
- `.contextupdate.toml` schema (TOML; version-gated).
- `.contextupdate.toml.example` template at the repo root.
- Three pressure scenarios (config flip, plan supersession, personal vs
  project) with fixtures and a grading harness.
- "Per-file copy-paste" section emitted after the report summary,
  grouping approved replacements by file. Always emitted; on no-write
  runtimes (Claude.ai) it's the deliverable, elsewhere it's a convenience
  for hand-applying.
- Claude.ai disambiguation prompt when two top-of-prompt context blocks
  (Project instructions, Personal preferences) can't be auto-labeled.
- Step 6 explicitly degrades to a no-op on no-write runtimes; Step 7
  emits a TOML copy-paste block instead of writing `.contextupdate.toml`.
- Expanded Claude.ai section in `docs/installing-per-runtime.md`
  covering invocation, watch surface, disambiguation, and copy-paste
  output.
- Cross-runtime packaging:
  - `.codex-plugin/plugin.json` (with `skills`, `hooks`, and `interface`
    fields) + `hooks/hooks-codex.json` for Codex.
  - `.cursor-plugin/plugin.json` + `hooks/hooks-cursor.json` for Cursor.
  - `.kimi-plugin/plugin.json` for Kimi Code, with `skillInstructions`
    mapping skill verbs onto Kimi's `AskUserQuestion`, `TodoList`,
    `Agent` (`subagent_type: explore` / `coder`), `Skill`, and
    `Read`/`Write`/`Edit`/`Bash`/`Grep`/`Glob`/`FetchURL`/`WebSearch`.
    Manifest wires `sessionStart.skill: "context-update-nudge"`.
  - `skills/context-update-nudge/` — tiny companion skill whose body
    is the same wrap-up reminder. Used on Kimi (no
    `additionalContext` injection surface) and as a manual fallback
    everywhere else. Keeps the workhorse skill invoke-on-demand.
  - `hooks/nudge.txt` — single source of truth for the reminder text.
    Consumed by `hooks/session-end-nudge` (bash),
    `.opencode/plugins/context-update.js` (Node), and
    `.pi/extensions/context-update.ts` (TypeScript); the Kimi nudge
    skill keeps a byte-identical copy with a "keep in sync" note.
  - `.opencode/plugins/context-update.js` + `.opencode/INSTALL.md` for
    OpenCode (registers the skills directory via the `config` hook and
    injects the session-start nudge via
    `experimental.chat.messages.transform`; idempotent via a marker
    check).
  - `.pi/extensions/context-update.ts` for Pi (uses
    `resources_discover` to register skills and `context` /
    `session_start` / `session_compact` / `agent_end` to inject the
    nudge with a marker guard).
  - `gemini-extension.json` + root `GEMINI.md` for Gemini CLI.
  - `scripts/build-claudeai-zip.sh` to produce a Claude.ai upload package
    from the skill source.
  - `docs/installing-per-runtime.md` with the per-target install matrix.
- Conversation-derived discovery as the primary watch-list source
  (`Read`/`Edit`/`Write` tool calls, `@file` mentions, tool-result and
  prose mentions, with per-signal confidence levels).
- Preloaded-context discovery for harness-loaded files
  (`CLAUDE.md`/`AGENTS.md`).
- In-flow config editing: `drop N`, `freeze N "reason"`, `watch PATH ...`
  replies at the Step 1 watch-list prompt; `ignore` and `freeze` added to
  the per-finding `Apply?` reply set. Queued edits persist in a new
  Step 7 with a single diff confirmation.
- New `[discovery]` toggles: `conversation_derived`,
  `conversation_min_confidence`, `preloaded_context`, `wellknown_probes`.

### Changed
- Slimmed the static well-known probe list to truly universal names.
  Removed guesses (`docs/plans/*`, `plans/*`, `.claude/memories/*`,
  `docs/conventions/*`, `CONVENTIONS.md`, `ARCHITECTURE.md`) — these are
  now picked up via conversation-derived discovery or config.
- `hooks/session-end-nudge`, `.opencode/plugins/context-update.js`, and
  `.pi/extensions/context-update.ts` now read the nudge text from
  `hooks/nudge.txt` instead of embedding it as a constant. Eliminates
  triple-source drift.
- `scripts/build-claudeai-zip.sh` switched from the external `zip`
  binary to Python's stdlib `zipfile`. Drops the `zip` prereq so the
  script runs on stock Git Bash for Windows (only `python3` is
  required). Header comment now documents the
  `bash scripts/build-claudeai-zip.sh` invocation and the Windows
  double-click pitfall. README + `docs/installing-per-runtime.md`
  gained matching invocation guidance and a troubleshooting table.
- `scripts/build-claudeai-zip.ps1` — native PowerShell equivalent of
  the bash builder. No Python or `zip` dependency. Uses
  `System.IO.Compression.ZipArchive` directly (not `Compress-Archive`,
  which on Windows PowerShell 5.1 produces backslash-separated entry
  names that violate the ZIP spec and cause Claude.ai to reject the
  upload with "Zip file contains path with invalid characters"). The
  shipped script forces forward-slash entry names regardless of host
  separator. README + install doc show both invocations
  (`powershell -ExecutionPolicy Bypass -File …` and `pwsh -File …`);
  troubleshooting table covers execution-policy errors and the
  backslash-entry-name failure.
- Bash/Python builder also belt-and-suspenders the entry-name
  separator (`replace(os.sep, '/').replace('\\', '/')`) for the same
  reason.

### Updated
- Claude.ai upload location moved from `Settings → Capabilities → Skills`
  to `Customize (left sidebar, alongside Chats and Projects) → Skills`
  — Customize is a top-level sidebar entry, not nested under Settings.
  README, install doc, and both builder scripts updated.
- Author / repository metadata across all manifests
  (`.claude-plugin`, `.codex-plugin`, `.cursor-plugin`, `.kimi-plugin`,
  `package.json`, `LICENSE`) now points at `benjaminliyo/ContextUpdate`
  with `Benjamin Li <benjaminliyo@gmail.com>` as the author.

### Deferred
- `[[mirror]]` block support (schema slot is reserved).
- `/context-update FILE1 FILE2 ...` explicit file args.
- Default-off `include_user_global` (currently default-on; revisit after
  user feedback).
- Wire `tests/run-skill-tests.sh` to a headless `claude` CLI smoke test
  for the three pressure scenarios. Today the harness is a manual
  scaffold (human runs the prompts in a real session and grades against
  the RED/GREEN rubric). Headless CI run would catch regressions on the
  skill body without a human in the loop.
