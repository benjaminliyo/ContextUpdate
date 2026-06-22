# ContextUpdate

An agent skill that checks your reusable context files for drift against
the *current conversation* — and proposes, never auto-applies, targeted edits.

Reusable-context files (`CLAUDE.md`, `AGENTS.md`, `~/.claude/CLAUDE.md`,
`docs/plans/*.md`, `.cursor/rules/*.mdc`, …) silently go stale as projects
evolve. A preference set on day 1 is overridden by a conversation on day 30,
and the file still says day 1. Future sessions then load the stale statement
as current. ContextUpdate is a cross-runtime agent skill — verified on
Claude Code and Codex Desktop (Windows), packaged for Claude.ai, Cursor,
Copilot CLI, Gemini CLI, Kimi Code, OpenCode, and Pi — that catches this
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
filesystem access. **The slim `context-update-project` variant is the
recommended Claude.ai path.** The full `context-update` zip is the
same coding-agent skill body packaged for upload; it's a
compatibility option for users who want one skill body across all
their tools, not a recommended Claude.ai entry point — it carries
filesystem/config/apply-loop behavior that Claude.ai cannot execute
directly.

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
discovers both skills via native lazy skill discovery — they appear
in the developer prompt's `<skills_instructions>` block with their
full descriptions. The SessionStart auto wrap-up nudge command in
`hooks/hooks-codex.json` invokes `hooks/codex-launcher.cmd`, a
cmd/bash polyglot: on Windows cmd.exe runs the batch portion and
dispatches to `hooks/session-end-nudge.ps1` (sidestepping Git Bash's
PATH/line-ending fragility); on Linux/macOS bash treats the cmd
portion as a heredoc no-op and execs the bash
`hooks/session-end-nudge` script directly.

> **Codex/Windows: launcher tested in isolation; Codex Desktop
> re-verification pending.** The Windows branch of the launcher
> dispatches to the same `session-end-nudge.ps1` command that was
> Codex Desktop / Windows verified on 0.142.0-alpha.6 in v0.1.2.
> The new `.cmd` wrapper around it parses correctly via cmd.exe in
> standalone testing (exit 0, correct JSON), but the polyglot
> launcher itself has not been exercised under Codex Desktop yet.
>
> **Codex/Linux + macOS: fallback implemented, not maintainer-verified.**
> The polyglot launcher's Unix branch execs `bash hooks/session-end-nudge`,
> which already emits the correct nested shape when Codex's
> `PLUGIN_ROOT` is set. Tested via Git Bash (POSIX-bash proxy on
> Windows) — exit 0, correct JSON. Should work on any Codex install
> that runs hook commands through a POSIX shell with `bash` available,
> but no maintainer device has exercised it. Reports welcome.

**Cursor**

Add this repo as a Cursor plugin source, or drop
`skills/context-update/` into `~/.agents/skills/` for the manual
route. The manifest at `.cursor-plugin/plugin.json` points
`skills` at `./skills/` and `hooks` at `./hooks/hooks-cursor.json`
(schema `version: 1`, lowercase `sessionStart`). Cursor also reads
`AGENTS.md` at the repo root. Invoke by message.

> **Known limitation (Cursor ≤ 3.1.15, May 2026):** Cursor's
> `sessionStart` hook fires and produces valid output, but Cursor
> drops the returned `additional_context` before it reaches the
> agent — a timing bug between hook execution and composer-handle
> creation
> ([forum thread](https://forum.cursor.com/t/sessionstart-hook-additional-context-is-never-injected-into-agents-initial-system-context/158452)).
> The skill itself still works; you just have to invoke it
> manually (by message or, if your build surfaces plugin slash
> commands, `/context-update`). The auto wrap-up nudge will start
> working again once Cursor ships the fix — no plugin change
> required.

**Copilot CLI** (requires Copilot CLI **≥ v1.0.11**)

Copilot CLI reads `AGENTS.md` at the project root and loads skills
from `~/.agents/skills/`. Copy `skills/context-update/` there.
Invoke by message.

To also wire the wrap-up nudge, copy `hooks/hooks.json` to one of
Copilot CLI's hook locations — Copilot does **not** load hooks
from a plugin folder:

- Per-repo: `.github/hooks/context-update.json`
- User-global: `~/.copilot/hooks/context-update.json`
  (`%USERPROFILE%\.copilot\hooks\` on Windows)

Set `COPILOT_CLI=1` in the hook's `env` so the
`hooks/session-end-nudge` script emits the flat-`additionalContext`
shape Copilot expects (this differs from VS Code / Claude Code's
nested `hookSpecificOutput` shape). The fix that makes
`additionalContext` actually reach the agent shipped in
[Copilot CLI v1.0.11](https://github.com/github/copilot-cli/blob/main/changelog.md)
on 2026-03-23; earlier versions silently drop it.

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

## Update

When a new version ships (manifest version bumped), refresh your local
install. The flow differs per runtime.

**Claude Code** (local marketplace)

```
/plugin marketplace update context-update-dev
/reload-plugins
```

`/plugin marketplace update` refreshes the marketplace metadata from
your local path; `/reload-plugins` applies the new version without a
session restart. If the new version doesn't appear, open `/plugin` →
**Marketplaces** → select `context-update-dev` → **Enable auto-update**
(local marketplaces have auto-update disabled by default). Verify with
`/plugin list` or the **Installed** tab.

**Claude.ai** (web / desktop)

Rebuild the slim project zip (default for Claude.ai-only users).

*Git Bash / macOS Terminal / Linux* (requires `python3` on PATH):

```bash
bash scripts/build-claudeai-project-zip.sh
```

*PowerShell on Windows*:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-claudeai-project-zip.ps1
```

Then in Customize → Skills, delete the old `context-update-project`
skill and upload the new zip (Claude.ai won't merge — old and new
can't co-exist).

For the full coding-agent variant (cross-runtime users), substitute
`build-claudeai-zip.{sh,ps1}` and the skill name `context-update`.

**Codex**

```
codex plugin marketplace upgrade context-update-dev
```

Restart the Codex session for the new skill body to load (skill
metadata refreshes on next launch).

**Cursor**

If the plugin was added via a team marketplace, toggle **Enable Auto
Refresh** on the marketplace (Cursor will pick up version bumps
automatically). Otherwise, re-import the repository URL through the
plugin source UI, then run **Developer: Reload Window**.

**Kimi Code**

```
/plugins
```

The plugin manager shows installed plugins with an
`update <local> → <latest>` indicator on any that have a newer
version. Select the entry, press Enter to update, then `/reload` to
apply (or `/new` for a fresh session).

**OpenCode**

OpenCode runs `bun install` at startup, so for git-source plugins
(like our `opencode.json` entry), a restart pulls the latest commit.
To force a refresh of plugin deps:

```
opencode upgrade        # CAVEAT: known to update the binary but skip plugins
```

For automatic plugin updates, add `opencode-plugin-auto-update` to
your plugin array — it polls for new versions and writes them back to
`opencode.json`.

**Pi**

```
pi update --extensions                                   # all extensions
pi update git:github.com/benjaminliyo/ContextUpdate      # this one only
```

Pi's update command pulls the latest from the source ref.

**Gemini CLI**

```
gemini extensions update context-update    # single
gemini extensions update                   # all user-scope
```

Must be run outside the interactive CLI session; restart the CLI for
the new skill body to load.

**Copilot CLI**

```
gh skill update
```

Uses provenance metadata (source repo, ref, tree SHA) written into
`SKILL.md` frontmatter at install time. For manual
`~/.agents/skills/` copies, re-copy the new `skills/context-update/`
directory and restart.

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

v0.1.2. See `CHANGELOG.md` for full history.

## License

MIT. See `LICENSE`.
