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
# Cross-platform dispatch lives in hooks/codex-launcher.cmd, a cmd/bash
# polyglot. On Windows cmd.exe runs the batch portion and invokes this
# .ps1; on Linux/macOS bash parses past the heredoc and execs the bash
# hooks/session-end-nudge instead.

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

function ConvertTo-JsonStringLiteral {
    param([Parameter(Mandatory = $true)][string]$Value)

    $builder = [System.Text.StringBuilder]::new()
    foreach ($char in $Value.ToCharArray()) {
        switch ($char) {
            '\' { [void]$builder.Append('\\') }
            '"' { [void]$builder.Append('\"') }
            "`b" { [void]$builder.Append('\b') }
            "`f" { [void]$builder.Append('\f') }
            "`n" { [void]$builder.Append('\n') }
            "`r" { [void]$builder.Append('\r') }
            "`t" { [void]$builder.Append('\t') }
            default {
                if ([int][char]$char -lt 0x20) {
                    [void]$builder.Append(('\u{0:x4}' -f [int][char]$char))
                } else {
                    [void]$builder.Append($char)
                }
            }
        }
    }

    $builder.ToString()
}

# Keep '<CONTEXT-UPDATE-REMINDER>' literal in stdout. PowerShell 7's
# ConvertTo-Json escapes it as \u003c...\u003e, and Codex's hook injection
# path may preserve that escaped text in the model context.
$escapedNudge = ConvertTo-JsonStringLiteral -Value $nudge
[Console]::Out.WriteLine('{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"' + $escapedNudge + '"}}')
exit 0
