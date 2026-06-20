# ContextUpdate

An agent skill that checks your reusable context files for drift against
the *current conversation* — and proposes, never auto-applies, targeted edits.

Reusable-context files (`CLAUDE.md`, `AGENTS.md`, `~/.claude/CLAUDE.md`,
`docs/plans/*.md`, `.cursor/rules/*.mdc`, …) silently go stale as projects
evolve. A preference set on day 1 is overridden by a conversation on day 30,
and the file still says day 1. Future sessions then load the stale statement
as current. ContextUpdate is a Claude Code skill plugin that catches this
on demand or at session wrap-up.

## What makes it different

Most existing tooling in this space is **code-driven** (git-diff based) or
operates *inside* an agent's memory store. ContextUpdate is
**conversation-driven**: it treats the live conversation as the source of
truth for recent decisions and the reusable-context files as the durable
record, then surfaces disagreements. See
[`docs/comparison-with-existing-tools.md`](docs/comparison-with-existing-tools.md).

## Install

The skill body is runtime-agnostic. Packaging differs per harness — see
[`docs/installing-per-runtime.md`](docs/installing-per-runtime.md) for
the full matrix. Quick paths:

**Claude Code** (local marketplace) — run these inside a Claude Code
session (not in PowerShell / your OS shell):
```
/plugin marketplace add /path/to/ContextUpdate
/plugin install context-update
```
Restart. The `<CONTEXT-UPDATE-REMINDER>` block should appear in the
first turn's context. Use `/context-update` or wait for the wrap-up
nudge.

**Claude.ai** (web / desktop)

Two skill packages target Claude.ai. Pick one:

| If you… | Skill | Builder script |
|---|---|---|
| Only use Claude.ai (no Claude Code / Codex / Cursor install) | **`context-update-project`** — slim, single-layer, copy-paste deliverable | `build-claudeai-project-zip.{sh,ps1}` |
| Also use Claude Code / Codex / Cursor and want the same skill body everywhere | **`context-update`** — full coding-agent skill | `build-claudeai-zip.{sh,ps1}` |

Web and desktop Claude.ai are the same target — neither gives the model
filesystem access. The slim variant is purpose-built for that
constraint; the full skill works there too but carries config-schema,
discovery-probe, and apply-loop content that has no effect on the web
surface.

#### Build the slim variant (recommended for Claude.ai-only users)

*Git Bash / macOS Terminal / Linux* (requires `python3` on PATH):

```bash
bash scripts/build-claudeai-project-zip.sh
```

*PowerShell on Windows*:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-claudeai-project-zip.ps1
```

Produces `dist/context-update-project-claudeai-<version>.zip`.

#### Build the full skill (cross-runtime users)

*Git Bash / macOS Terminal / Linux*:

```bash
bash scripts/build-claudeai-zip.sh
```

*PowerShell on Windows*:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-claudeai-zip.ps1
```

Produces `dist/context-update-claudeai-<version>.zip`.

> On Windows, **do not** double-click the `.sh` file or run it from
> cmd.exe / PowerShell — it opens in an editor instead of executing.
> Use Git Bash with the `bash …` form, or use the PowerShell script.
> PowerShell 7+ users can substitute `pwsh` for `powershell`.

#### Upload

Open Claude.ai → Customize (left sidebar, alongside Chats and Projects)
→ Skills, upload the zip, enable it on the Project or conversation.
Trigger by `/context-update` (if your Claude.ai version surfaces plugin
slash commands) or by message: *"run context update on this
conversation"*. See
[`docs/installing-per-runtime.md`](docs/installing-per-runtime.md) for
the troubleshooting table.

**Codex**

Add this repo as a Codex plugin source per the Codex docs for your
install method. Codex picks up `.codex-plugin/plugin.json` and
`hooks/hooks-codex.json` (which uses `${PLUGIN_ROOT}` and the
`startup|resume|clear` matcher). The same `hooks/session-end-nudge`
script runs and emits Codex's `hookSpecificOutput.additionalContext`
shape. No slash command — invoke by message
(*"run context-update on this conversation"*).

**Cursor**

Add this repo as a Cursor plugin source, or drop
`skills/context-update/` into `~/.agents/skills/` for the manual
route. The manifest at `.cursor-plugin/plugin.json` points
`skills` at `./skills/` and `hooks` at `./hooks/hooks-cursor.json`
(schema `version: 1`, lowercase `sessionStart`). Cursor also reads
`AGENTS.md` at the repo root. Invoke by message.

**Copilot CLI**

Copilot CLI reads `AGENTS.md` at the project root and loads skills
from `~/.agents/skills/`. Copy `skills/context-update/` there. If
you also wire the hook, `hooks/hooks.json` works as-is — the nudge
script detects Copilot via `COPILOT_CLI=1` and emits the top-level
`additionalContext` SDK shape. Invoke by message.

**Gemini CLI**

Drop the repo as a Gemini extension: it ships `gemini-extension.json`
and `GEMINI.md` at the root. Skills load from `~/.gemini/skills/` per
Gemini conventions. No hook surface for the wrap-up nudge — invoke
the skill by message.

**Kimi Code**

Add this repo as a Kimi plugin source. `.kimi-plugin/plugin.json`
points `skills` at `./skills/` and ships a `skillInstructions` tool
mapping so the skill's instructions resolve to Kimi's actual tool
names. Because Kimi has no `additionalContext` injection surface,
`sessionStart.skill` always-loads the tiny companion skill
`skills/context-update-nudge/` whose body **is** the wrap-up nudge.
The full skill stays invoke-on-demand via Kimi's native `Skill` tool.

**OpenCode**

Add to your `opencode.json`:

```json
{
  "plugin": ["context-update@git+https://github.com/benjaminliyo/ContextUpdate.git"]
}
```

The plugin (`.opencode/plugins/context-update.js`) registers the
skills path via the `config` hook and injects the
`<CONTEXT-UPDATE-REMINDER>` nudge via
`experimental.chat.messages.transform` (idempotent via marker
check). Invoke by message or OpenCode's native `skill` tool. See
`.opencode/INSTALL.md` for the full guide.

**Pi**

Install the extension at `.pi/extensions/context-update.ts` per Pi's
extension install flow. It registers `./skills` via
`resources_discover` and injects the nudge in the `context` event,
re-armed across `session_start` / `session_compact`. Invoke by
message.

For the manifest/hook matrix and a per-runtime troubleshooting table,
see [`docs/installing-per-runtime.md`](docs/installing-per-runtime.md).

## Use

- **Manual:** run `/context-update` whenever you want to audit the watched
  files against the current conversation.
- **Override frozen files:** `/context-update --override-frozen` (per-file
  confirmation still required).
- **Wrap-up nudge:** the SessionStart hook plants a self-reminder so the
  model considers running the skill before declaring a session done.

The skill **never edits a watched file without your explicit per-file
approval**.

## Configuration

`.contextupdate.toml` at the repo root is optional. Without it, the skill
auto-discovers files via the conversation itself (`Read`/`Edit`/`Write`
tool calls, `@file` mentions), preloaded context (`CLAUDE.md`,
`AGENTS.md`), a slim probe list, and reference-following up to depth 2.

**You generally don't need to hand-edit a config file.** During a
`/context-update` run:

- At the watch-list prompt (Step 1), reply with `drop N`,
  `freeze N "reason"`, or `watch PATH` to prune or extend the list.
- At each finding's `Apply?` prompt, `ignore` and `freeze` are
  available alongside `y / n / edit / skip`.

The skill queues the choices and asks once at the end before writing them
to `.contextupdate.toml` (creating it if absent).

If you prefer hand-editing, copy the template:

```
cp .contextupdate.toml.example .contextupdate.toml
```

See
[`skills/context-update/references/config-schema.md`](skills/context-update/references/config-schema.md)
for the full schema and
[`skills/context-update/references/discovery-rules.md`](skills/context-update/references/discovery-rules.md)
for how the five discovery sources merge.

## Layout

- `skills/context-update/` — the skill itself (SKILL.md + references).
- `skills/context-update-project/` — Claude.ai-only variant (single-layer,
  no filesystem, copy-paste deliverable).
- `commands/context-update.md` — `/context-update` slash command (Claude Code).
- `hooks/` — SessionStart-planted wrap-up reminder + per-runtime hook configs
  (`hooks.json` for Claude Code/Copilot, `hooks-codex.json`,
  `hooks-cursor.json`).
- `.claude-plugin/` — Claude Code manifest and local marketplace entry.
- `.codex-plugin/` — Codex manifest.
- `.cursor-plugin/` — Cursor manifest.
- `.kimi-plugin/` — Kimi Code manifest with Kimi tool mapping.
- `.opencode/` — OpenCode plugin (`plugins/context-update.js`) + INSTALL.md.
- `.pi/` — Pi extension (`extensions/context-update.ts`).
- `gemini-extension.json`, `GEMINI.md` — Gemini CLI entry points.
- `AGENTS.md` — Codex/Copilot/Cursor working instructions.
- `scripts/build-claudeai-zip.sh` — packages the skill for Claude.ai upload.
- `scripts/build-claudeai-project-zip.sh` — packages the Claude.ai-only variant.
- `tests/` — pressure scenarios + fixtures + grading scaffold.
- `docs/` — design rationale, comparisons, install-per-runtime.

## Status

v0.1.0 — MVP scaffold. See `RELEASE-NOTES.md`.

## License

MIT. See `LICENSE`.
