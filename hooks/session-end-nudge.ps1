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
# Cross-platform dispatch lives in hooks/hooks-codex.json, which registers
# two SessionStart (and UserPromptSubmit) hook entries: one calling
# `powershell -File hooks/session-end-nudge.ps1` (this script) and one
# calling `bash hooks/session-end-nudge`. On each platform one entry
# succeeds (interpreter present) and the other fails (interpreter not on
# PATH). Codex surfaces the failing entry as a notification but the
# succeeding entry still injects the nudge.

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
# path may preserve that escaped text in the model context. Emit both the
# nested and flat context keys because Codex hook builds have differed on
# which shape they honor.
$escapedNudge = ConvertTo-JsonStringLiteral -Value $nudge
[Console]::Out.WriteLine('{"additionalContext":"' + $escapedNudge + '","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"' + $escapedNudge + '"}}')
exit 0
