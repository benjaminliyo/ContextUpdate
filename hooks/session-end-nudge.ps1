#Requires -Version 5.0
# Codex SessionStart hook (Windows): emits the wrap-up nudge as
# hookSpecificOutput.additionalContext.
#
# Why this exists alongside the bash session-end-nudge:
# Codex's marketplace sync on Windows converts the bash script's LF endings
# to CRLF, which breaks bash's parsing of the elif chain that selects the
# output shape. This PowerShell version is native to Windows, has no
# Git Bash dependency, no /usr/bin PATH issue, and no line-ending fragility.
#
# Cross-platform dispatch lives in hooks/hooks-codex.json, which chains
# `powershell ... || bash ...`. On Windows powershell.exe succeeds and the
# fallback never fires; on Linux/macOS powershell exits 127 (command not
# found) and the shell falls back to running hooks/session-end-nudge.

$ErrorActionPreference = 'Stop'

# Force UTF-8 stdout without BOM. PowerShell 5.1 sometimes defaults to
# UTF-16 LE on the output stream, which Codex's JSON parser would reject.
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$nudgePath = Join-Path -Path $PSScriptRoot -ChildPath 'nudge.txt'

if (-not (Test-Path -LiteralPath $nudgePath)) {
    [Console]::Error.WriteLine("context-update: nudge file missing at $nudgePath")
    exit 1
}

# Use .NET directly to read the file as a plain System.String. Get-Content's
# wrapped string object gets serialized as {value: "..."} by ConvertTo-Json
# in PowerShell 5.1, which Codex would reject.
$nudge = [System.IO.File]::ReadAllText($nudgePath)

$payload = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName     = 'SessionStart'
        additionalContext = $nudge
    }
}

# -Compress avoids PowerShell 5.1's wide-indented JSON; Codex parses either,
# but compressed output is one line and easier to log/diff.
$payload | ConvertTo-Json -Depth 5 -Compress
exit 0
