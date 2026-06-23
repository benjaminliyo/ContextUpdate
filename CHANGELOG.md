# Changelog

All notable changes to this plugin will be documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed
- Codex auto wrap-up nudge now works on both Codex/Windows and
  Codex/macOS+Linux via **dual hook entries** in `hooks/hooks-codex.json`.
  Two `SessionStart` (and two `UserPromptSubmit`) entries are registered:
  one calling `powershell -File hooks/session-end-nudge.ps1` directly,
  one calling `bash hooks/session-end-nudge` directly. On each platform
  one interpreter is present and injects the nudge; the other fails with
  "interpreter not found" and Codex surfaces it as a per-entry
  notification. Direct invocation matches the form that was verified
  working on Codex/Windows in v0.1.2 — no cmd.exe wrapper in between,
  no inline shell-chain operators.
- The interim `hooks/codex-launcher.cmd` polyglot has been removed.
  Diagnosing with the user revealed that even though the launcher
  emitted correct stdout in every isolated test (cmd.exe, PowerShell,
  Git Bash), Codex Desktop completed the hook without injecting context.
  The direct PowerShell command works without the cmd.exe shim, so the
  launcher and its `.gitattributes` LF override are gone.
- Codex SessionStart nudge preserves the literal
  `<CONTEXT-UPDATE-REMINDER>` marker on Windows. PowerShell 7's
  `ConvertTo-Json` escaped `<`, `>`, and `'` as `<`, `>`,
  and `'`; Codex's hook context path can preserve that escaped
  text, so the model never sees the literal marker. The PowerShell hook
  writes compact JSON with a small JSON string escaper that leaves the
  marker literal while still escaping newlines, quotes, backslashes, and
  control characters.
- Codex SessionStart hook output includes both top-level
  `additionalContext` and nested `hookSpecificOutput.additionalContext`
  for Codex-like environments. Keeps the previously verified nested shape
  while covering Codex builds that complete the hook but appear to
  ignore the nested-only payload. The bash `session-end-nudge` and
  `session-end-nudge.ps1` both emit this dual-key form.
- `tests/verify-codex-surface.ps1` regression-tests the Codex hook
  output (literal marker presence, both flat and nested
  `additionalContext` keys) and asserts `hooks/hooks-codex.json`
  registers dual `SessionStart` and `UserPromptSubmit` entries with one
  powershell and one bash command each.
- Failed Codex/Windows experiments captured for future reference:
  (a) inline `powershell ... || bash ...` chain — Codex/Windows does
  not interpret `||` as a shell OR-chain; trailing tokens went to
  PowerShell as positional args, hook exited 1. (b) cmd/bash polyglot
  launcher (`hooks/codex-launcher.cmd`) — emitted correct stdout in
  every isolated test, but Codex Desktop completed the hook without
  injecting context. Both were superseded by the dual-entry approach.
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
