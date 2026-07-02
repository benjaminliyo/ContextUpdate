# Installing per runtime

The skill body (`skills/context-update/SKILL.md` + `references/`) is
runtime-agnostic markdown. What changes per harness is the packaging
manifest, the hook payload shape, and the discovery path. This doc lists
the files this repo ships for each target and how to install.

## Matrix

| Runtime | Manifest | Hook config | Hook script | Slash command |
|---|---|---|---|---|
| Claude Code | `.claude-plugin/{plugin,marketplace}.json` | `hooks/hooks.json` | `hooks/session-end-nudge` | `commands/context-update.md` |
| Claude.ai | (zip built via script) | — | — | — |
| Codex | `.codex-plugin/plugin.json` | `hooks/hooks-codex.json` | `hooks/session-end-nudge` | — |
| Cursor | `.cursor-plugin/plugin.json` | `hooks/hooks-cursor.json` | `hooks/session-end-nudge` | — |
| Copilot CLI | (reads `AGENTS.md` + skills dir) | reuses `hooks/hooks.json` shape | `hooks/session-end-nudge` (branches on `COPILOT_CLI=1`) | — |
| Antigravity CLI | `plugin.json` + `AGENTS.md` | `hooks.json` | `hooks/session-end-nudge` / `.ps1` | — |
| Gemini CLI (Legacy) | `gemini-extension.json` + `GEMINI.md` | — | — | — |
| Kimi Code | `.kimi-plugin/plugin.json` | `sessionStart.skill: context-update-nudge` | `skills/context-update-nudge/SKILL.md` | — |
| OpenCode | `.opencode/plugins/context-update.js` | (in-plugin nudge inject) | (in-plugin nudge inject) | — |
| Pi | `.pi/extensions/context-update.ts` | (in-extension nudge inject) | (in-extension nudge inject) | — |

Slash commands and SessionStart hooks are first-class on Claude Code only.
Other runtimes either reuse the hook surface with their own payload shape
or have no equivalent — the skill still works, the user just invokes it
by message instead.

---

## Claude Code

Run these inside a Claude Code session (not in your OS shell):

```
/plugin marketplace add /path/to/ContextUpdate
/plugin install context-update
```

Restart. Confirm the `<CONTEXT-UPDATE-REMINDER>` block appears in the
first turn. Use `/context-update` or wait for the wrap-up nudge.

## Claude.ai (web / desktop)

Claude.ai's Skills surface uses zip uploads — no plugin manifests and no
SessionStart hooks. (Slash-command support varies; try `/context-update`
first and fall back to a message invocation if it isn't registered.)

### Pick a variant

Two skill packages target Claude.ai:

| If you… | Skill | Builder | Output zip |
|---|---|---|---|
| Only use Claude.ai (no Claude Code / Codex / Cursor install) | **`context-update-project`** — slim, single-layer, copy-paste deliverable, no filesystem assumptions | `scripts/build-claudeai-project-zip.{sh,ps1}` | `dist/context-update-project-claudeai-<version>.zip` |
| Also use Claude Code / Codex / Cursor and want the same skill body everywhere | **`context-update`** — full coding-agent skill | `scripts/build-claudeai-zip.{sh,ps1}` | `dist/context-update-claudeai-<version>.zip` |

Both scripts come in bash and PowerShell flavors. Both bash variants
require `python3` on PATH; both PowerShell variants are self-contained.
The sections below cover the full-skill builder; substitute the file
name to build the slim variant — the flags and troubleshooting are
identical.

### Build and upload

Two scripts ship — pick the one for your shell. Both produce the same
`dist/context-update-claudeai-<version>.zip` (or the
`context-update-project-claudeai-<version>.zip` variant if you
substituted the slim script name).

**Bash** (Git Bash on Windows, macOS Terminal, Linux). Requires
`python3` on PATH. No external `zip` binary needed — the script uses
Python's stdlib `zipfile`, so stock Git Bash for Windows works without
msys2 / `zip` install. Run from the repo root:

```bash
bash scripts/build-claudeai-zip.sh
```

**PowerShell** (Windows). No extra prereqs — uses built-in
`Compress-Archive` and `ConvertFrom-Json` (PowerShell 5.0+, which ships
with Windows 10+). From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-claudeai-zip.ps1
```

Or, if your session's execution policy already allows local scripts:

```powershell
.\scripts\build-claudeai-zip.ps1
```

PowerShell 7+ users can substitute `pwsh` for `powershell`.

> Windows pitfall: do **not** double-click the `.sh` file or run it as
> `./scripts/build-claudeai-zip.sh` from cmd.exe / PowerShell — that
> opens it in an editor. Use Git Bash + `bash …`, or use the PowerShell
> script.

On success the last line prints:

```
Built: <repo>/dist/context-update-claudeai-<version>.zip
```

Then in Claude.ai:

1. Customize (left sidebar) → Skills.
2. Upload the zip.
3. Enable the skill on the projects/conversations where you want it.

### Troubleshooting the build

| Symptom | Cause / fix |
|---|---|
| Double-click opens the script in an editor | Windows file association. Use Git Bash + `bash scripts/build-claudeai-zip.sh`, or the PowerShell script. |
| `python3: command not found` (bash) | Install Python 3 and ensure it's on PATH. On Windows, the Microsoft Store Python installer wires `python3` automatically. Or use the PowerShell script — it has no Python dependency. |
| `…cannot be loaded because running scripts is disabled on this system` (PowerShell) | Execution policy blocks unsigned local scripts. Use `powershell -ExecutionPolicy Bypass -File scripts\build-claudeai-zip.ps1` to bypass for this run only, or `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` to allow local scripts permanently. |
| `Compress-Archive : The term … is not recognized` (PowerShell) | PowerShell < 5.0. Upgrade to Windows PowerShell 5.1 (ships with Windows 10+) or install PowerShell 7. |
| Claude.ai upload fails: `Zip file contains path with invalid characters` | The zip has backslash-separated entry names. Caused by Windows PowerShell 5.1's `Compress-Archive`. **The `.ps1` shipped here avoids this** by using `System.IO.Compression.ZipArchive` directly with forced forward slashes. If you built the zip with some other tool, rebuild with the supplied script — or open the zip in 7-Zip / WinRAR and check that entry names use `/`, not `\`. |
| `skill source not found at …/skills/context-update` | You're not in the repo root. `cd` there first. |
| Zip uploads to Claude.ai but the skill doesn't appear | Confirm the zip's top-level entry matches the variant: `context-update/SKILL.md` for the full skill, or `context-update-project/SKILL.md` for the slim Claude.ai project skill. Each builder script enforces its own layout. Unzip locally to verify. |

### Invocation

- `/context-update` if your Claude.ai version surfaces plugin slash
  commands.
- Otherwise by message: *"run context-update on this conversation"*. The
  frontmatter description matches the same way it does in Claude Code.

### What gets watched

Claude.ai skills have no filesystem access. The watch list is everything
the skill can see in its own context:

- **Project instructions** — injected into the system prompt when the
  conversation is in a Project.
- **Personal preferences** / User style — also injected into the system
  prompt.
- **Files uploaded to the Project** or attached to the conversation.
- **Pasted blocks** in the conversation.

Conversation-derived discovery still works for anything pasted or
uploaded. Files on your local disk are *not* checkable from Claude.ai —
upload or paste them if you want them watched.

### Disambiguating Project vs Personal

Claude.ai delimits the two top-of-prompt sections, but the wrapper text
varies by client version. If the skill can identify both sections by
marker, it labels them automatically. If it can't, it asks once before
producing the report:

```
I see two context blocks I can't label with confidence. Which is which?
  A — "<first ~80 chars>..."
  B — "<first ~80 chars>..."
Reply: `A=personal, B=project` (or vice versa).
```

One question, then proceed.

### Output: copy-paste, not auto-edit

Because there are no file-write tools on Claude.ai, Step 6 doesn't write
anywhere. Instead, the report emits a **"Per-file copy-paste"** section
after the summary, grouping approved replacements by file. The user:

1. Reads the per-file block for the file they want to update.
2. Copies the proposed replacement(s).
3. Pastes into Claude.ai's editor — Project settings → Instructions for
   project context, or Personal preferences / User style for global.

Step 7 (config persistence) similarly degrades: if any `[[watch]]` /
`[[ignore]]` / `[[freeze]]` blocks were queued, the skill emits a single
TOML snippet for you to paste into `.contextupdate.toml` by hand. (On
Claude.ai you typically won't have a `.contextupdate.toml` to begin with;
the snippet is mainly useful if you're using Claude.ai alongside a
Claude Code project that *does* have one.)

## Codex

- Manifest: `.codex-plugin/plugin.json`
- Skills: discovered via Codex's native lazy enumeration. Both
  `context-update` and `context-update-config` show up in the
  developer prompt's `<skills_instructions>` block with their full
  descriptions; the agent invokes them when relevant.
- Hook config: `hooks/hooks-codex.json` registers **two
  SessionStart entries** (matcher `startup|resume|clear`). The first
  calls `powershell -NoProfile -ExecutionPolicy Bypass -File
  hooks/session-end-nudge.ps1` directly; the second calls
  `bash hooks/session-end-nudge` directly. On each platform one
  interpreter is the native fit and that hook injects the nudge;
  the other fails with exit code 1, which Codex surfaces as
  "SessionStart hook (failed)" alongside the successful one. The
  notification is cosmetic — the reminder still reaches the model.
- `hooks/session-end-nudge.ps1` is byte-identical to its v0.1.2 form:
  it reads `hooks/nudge.txt`, builds an `[ordered]` hashtable with
  `hookSpecificOutput.hookEventName = SessionStart` and
  `additionalContext = <nudge text>`, and emits it via
  `ConvertTo-Json -Compress`. PowerShell 5.1's auto-escaping turns
  `<` and `>` into `<` / `>` in the JSON; Codex's hook
  ingestion un-escapes them when injecting into model context, so
  the literal `<CONTEXT-UPDATE-REMINDER>` block appears intact in
  the agent's prompt.
- `hooks/session-end-nudge` (bash) is byte-identical to its v0.1.2
  form and emits the same nested-only JSON for any runtime whose
  env var fingerprint is Codex-like (`PLUGIN_ROOT` set,
  `COPILOT_CLI` unset).
- Failed approaches captured for future reference, in chronological
  order:
  (1) inline `powershell … || bash …` in the `command` field —
  Codex/Windows does not interpret `||` as a shell OR-chain; the
  trailing tokens went to PowerShell as positional args and the hook
  exited 1.
  (2) cmd/bash polyglot launcher `hooks/codex-launcher.cmd` —
  emitted correct stdout in every isolated test (cmd.exe via
  PowerShell, Git Bash) but Codex Desktop completed the hook
  without injecting the context.
  (3) dual-key JSON via a custom in-script escaper in
  `session-end-nudge.ps1` (preserving literal `<>` and emitting
  both top-level `additionalContext` AND nested
  `hookSpecificOutput.additionalContext`) plus a `UserPromptSubmit`
  hook entry — combined regression broke injection; methodical
  bisection from the v0.1.2 baseline isolated dual-entry hooks as
  safe and rolled the rest back.

### Verification status

| Platform | Status |
|---|---|
| Codex Desktop / Windows | **Verified** — current Codex Desktop build, 2026-06-22. PowerShell entry injects the literal `<CONTEXT-UPDATE-REMINDER>` block. Bash entry fails ("SessionStart hook (failed) — hook exited with code 1") because of Codex's LF→CRLF marketplace-sync corruption of the bash script. Cosmetic; the reminder still reaches the model. |
| Codex / Linux + macOS | **Not maintainer-verified.** Bash entry should run since bash is the native interpreter and the marketplace-sync CRLF issue does not affect Unix checkouts. PowerShell entry fails since `powershell` isn't standard on Unix. Same cosmetic "1 of 2 hooks failed" notification, inverse cause. Reports welcome. |

Install by adding this repo as a Codex plugin source per the Codex docs
for your install method.

### Why PowerShell on Windows instead of bash

Other Windows runtimes (Claude Code, Cursor, Copilot CLI) drive the
hook through `hooks/run-hook.cmd` → Git Bash → `session-end-nudge`.
That path doesn't work on Codex Desktop because Codex's marketplace
sync on Windows re-encodes the bash script's LF endings to CRLF,
which breaks bash's parsing of the elif chain that selects the
output JSON shape. We diagnosed three layers — `/usr/bin` not on
PATH, Codex JSON shape mismatch, and CRLF corruption — before
landing on PowerShell as the Windows fix. PowerShell is native
Windows, has no Git Bash dependency, no `/usr/bin` PATH issue, and
no line-ending fragility. The Codex/Windows hook command directly
invokes `powershell -File hooks/session-end-nudge.ps1`, which writes
nested-shape JSON via `[System.IO.File]::ReadAllText` and
`ConvertTo-Json -Compress`.
Linux/macOS were never hit by the marketplace-sync CRLF issue, so
the second `SessionStart` entry — direct `bash
hooks/session-end-nudge` — works there. The bash script emits the
same nested-shape JSON; only the interpreter differs.

## Cursor

- Manifest: `.cursor-plugin/plugin.json` (points `skills` at `./skills/`
  and `hooks` at `./hooks/hooks-cursor.json`).
- Hook config: `hooks/hooks-cursor.json` (Cursor schema: `version: 1`,
  lowercase `sessionStart`, relative `./hooks/run-hook.cmd` command).
- Hook script: same `hooks/session-end-nudge`. Branches on
  `CURSOR_PLUGIN_ROOT` and emits `additional_context` (snake_case),
  which Cursor expects.
- Cursor also reads `AGENTS.md` at the project root for working
  instructions.

Install by adding this repo as a Cursor plugin source per the Cursor
docs for your install method, or drop the `skills/context-update/`
folder into Cursor's skills location (`~/.agents/skills/` is the
cross-runtime alias) if you prefer the older manual route.

### Known limitation (Cursor ≤ 3.1.15)

As of Cursor 3.1.15 (May 2026), the `sessionStart` hook fires and
produces valid stdout, but Cursor drops the returned
`additional_context` before it reaches the agent's initial context.
This is a known Cursor bug
([forum #158452](https://forum.cursor.com/t/sessionstart-hook-additional-context-is-never-injected-into-agents-initial-system-context/158452)) —
the manifest and hook script in this repo are spec-correct.
Workaround: invoke the skill manually until Cursor ships the fix.
No plugin change will be required when they do.

## Copilot CLI

Requires Copilot CLI **≥ v1.0.11** (the
[2026-03-23 release](https://github.com/github/copilot-cli/blob/main/changelog.md)
that fixed
[#2142](https://github.com/github/copilot-cli/issues/2142) —
`onSessionStart` `additionalContext` was fire-and-forget on
v1.0.8–v1.0.10 and never reached the agent).

- Reads `AGENTS.md` at the project root.
- Skills load from `~/.agents/skills/`.
- **Hook installation is manual** — Copilot CLI does not load
  hooks from a plugin folder. Copy `hooks/hooks.json` to either:
  - Per-repo: `.github/hooks/context-update.json`
  - User-global: `~/.copilot/hooks/context-update.json`
    (`%USERPROFILE%\.copilot\hooks\` on Windows, or
    `$COPILOT_HOME/hooks/` if that variable is set).
- Set `COPILOT_CLI=1` in the hook's `env` block so
  `session-end-nudge` emits the flat top-level `additionalContext`
  shape Copilot CLI expects (Copilot rejects the
  `hookSpecificOutput` wrapper that VS Code / Claude Code use).

## Antigravity CLI (agy)

- **Plugin manifest:** `plugin.json` at the repo root.
- **Hook configuration:** `hooks.json` at the repo root (registers a `SessionStart` command-type hook).
- **Staging path:** Staged inside `~/.gemini/antigravity-cli/plugins/context-update/`.
- **Nudge script:** `hooks/session-end-nudge` (bash) or `hooks/session-end-nudge.ps1` (powershell) which emits the `hookSpecificOutput` JSON format containing the `<CONTEXT-UPDATE-REMINDER>` block.

### Installation & Update
Install (or update by reinstalling) the plugin:

```bash
agy plugin install /path/to/ContextUpdate
```

Verify that it is active:

```bash
agy plugin list
```

## Gemini CLI (Legacy / Enterprise only)

> [!NOTE]
> Gemini CLI was decommissioned for individual accounts on June 18, 2026. The information below is preserved for compatibility with enterprise or legacy environments.

- Extension manifest: `gemini-extension.json` at the repo root.
- Context file: `GEMINI.md` at the repo root (points at SKILL.md and
  mirrors the working instructions).
- Skills load from `~/.gemini/skills/` per Gemini CLI conventions.
- No hook surface for the session-end nudge; users invoke the skill by
  message.

## Kimi Code

- Manifest: `.kimi-plugin/plugin.json` (points `skills` at `./skills/`
  and ships a Kimi-specific `skillInstructions` tool mapping in the
  manifest itself).
- The mapping covers `AskUserQuestion`, `TodoList`, `Agent`
  (`subagent_type: "explore"` / `"coder"`), the native `Skill` tool,
  and `Read`/`Write`/`Edit`/`Bash`/`Grep`/`Glob`/`FetchURL`/`WebSearch`
  — so the skill's "ask the user", "dispatch a subagent", "read fresh",
  and "apply the diff" instructions resolve to Kimi's actual tool names.
- Kimi has no `additionalContext` injection surface, so the manifest's
  `sessionStart.skill` is wired to a tiny companion skill
  `skills/context-update-nudge/` whose body **is** the same nudge
  text every other runtime plants via SessionStart hook or plugin
  injection. The full `context-update` skill body stays
  invoke-on-demand — the agent loads it (via Kimi's native `Skill`
  tool) only when the nudge fires the wrap-up condition.
- Install by adding this repo as a Kimi plugin source per the Kimi
  Code docs for your install method.

## OpenCode

- Plugin: `.opencode/plugins/context-update.js`.
- Install via `opencode.json`:

  ```json
  {
    "plugin": ["context-update@git+https://github.com/benjaminliyo/ContextUpdate.git"]
  }
  ```

- The plugin uses two hooks:
  - `config` — appends `./skills/` (resolved from the plugin's own
    location) to `config.skills.paths` so OpenCode discovers
    `context-update` without symlinks.
  - `experimental.chat.messages.transform` — injects the same
    `<CONTEXT-UPDATE-REMINDER>` nudge that the Claude Code SessionStart
    hook plants. Idempotent via a marker check, so re-injection is
    safe across agent steps.
- The plugin does NOT inline the full SKILL.md — the body stays
  invoke-on-demand. Trigger the skill by message
  (*"run context-update on this conversation"*) or via OpenCode's
  native `skill` tool.
- See `.opencode/INSTALL.md` for the full install/troubleshoot guide
  and OpenCode tool mapping (`read`, `apply_patch`, `bash`, `grep`,
  `glob`, `webfetch`, `task`, `todowrite`).

## Pi

- Extension: `.pi/extensions/context-update.ts`.
- Uses Pi's `ExtensionAPI` from `@earendil-works/pi-coding-agent` with
  events:
  - `resources_discover` — registers `./skills` so Pi finds the
    skill folder.
  - `session_start` / `session_compact` — re-arm the injection flag
    so the nudge gets re-planted after compaction.
  - `agent_end` — disarms injection.
  - `context` — inserts the `<CONTEXT-UPDATE-REMINDER>` user message
    after any leading `compactionSummary` messages, guarded by a
    marker check to prevent double-injection.
- Same design choice as OpenCode: only the short nudge is injected,
  not the full SKILL.md.

---

## Smoke test per runtime

1. Install.
2. Open a session in `tests/fixtures/repo-a-clean/`.
3. (Harnesses with hooks) Verify the `<CONTEXT-UPDATE-REMINDER>` block
   appears in the model's context on the first turn.
4. Run scenario 01 manually (switch to vitest mid-conversation, then
   wrap up).
5. Confirm the consolidated report contains: a numbered finding for
   the jest→vitest drift, a fenced ```diff block showing the change,
   and an `Apply all` prompt. The exact user quote may not appear
   verbatim in user-facing output (it lives in the agent's internal
   extraction).
