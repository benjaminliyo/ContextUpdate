# Installing Context Update for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add context-update to the `plugin` array in your `opencode.json` (global or
project-level):

```json
{
  "plugin": ["context-update@git+https://github.com/benjaminliyo/ContextUpdate.git"]
}
```

Restart OpenCode. The plugin installs through OpenCode's plugin manager,
registers the `context-update` skill, and injects a short reminder into the
first user message of each session.

Verify by asking: "what is context-update?"

OpenCode uses its own plugin install. If you also use Claude Code, Codex,
Cursor, Kimi, or Pi, install Context Update separately for each one.

## Usage

The skill is invoke-on-demand — it is **not** always-loaded. Trigger it by
message ("run context-update on this conversation") or, if your OpenCode
build surfaces plugin slash commands, `/context-update`.

Use OpenCode's native `skill` tool to list and load the skill manually:

```
use skill tool to load context-update
```

## Tool mapping

The skill speaks in actions ("read a file fresh", "apply this diff",
"dispatch a subagent"). On OpenCode these resolve to:

- "Read a file" → `read`
- "Create / edit / delete a file" → `apply_patch`
- "Run a shell command" → `bash`
- "Search file contents" / "find files by name" → `grep`, `glob`
- "Fetch a URL" → `webfetch`
- "Invoke a skill" → OpenCode's native `skill` tool
- "Dispatch a subagent" → `task` with `subagent_type: "general"` (or
  `"explore"` for read-only file inspection)
- "Create a todo" → `todowrite`

## Updating

OpenCode installs Context Update through a git-backed package spec. Some
OpenCode and Bun versions pin that resolved git dependency in a lockfile
or cache, so a restart may not pick up the newest commit. If updates do
not appear, clear OpenCode's package cache or reinstall the plugin.

To pin a specific version:

```json
{
  "plugin": ["context-update@git+https://github.com/benjaminliyo/ContextUpdate.git#v0.1.0"]
}
```

## Troubleshooting

### Plugin not loading

1. Check logs: `opencode run --print-logs "hello" 2>&1 | grep -i context-update`
2. Verify the plugin line in your `opencode.json`.
3. Make sure you're running a recent version of OpenCode.

### Skill not discovered

1. Use `skill` tool to list what's discovered.
2. Check that the plugin is loading (see above).

### Windows install issues

Some Windows OpenCode builds have upstream issues with git-backed plugin
specs. If OpenCode cannot install the plugin, install with system npm and
point OpenCode at the local package:

```powershell
npm install context-update@git+https://github.com/benjaminliyo/ContextUpdate.git --prefix "$HOME\.config\opencode"
```

Then use the installed package path in `opencode.json`:

```json
{
  "plugin": ["~/.config/opencode/node_modules/context-update"]
}
```
