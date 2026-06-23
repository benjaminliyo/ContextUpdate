param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$skillPath = Join-Path $Root "skills/context-update-config/SKILL.md"
if (-not (Test-Path -LiteralPath $skillPath)) {
    throw "Missing Codex-discoverable skill: skills/context-update-config/SKILL.md"
}

$skillText = Get-Content -LiteralPath $skillPath -Raw
if ($skillText -notmatch "(?m)^name:\s*context-update-config\s*$") {
    throw "context-update-config skill frontmatter must declare name: context-update-config"
}

$manifestPath = Join-Path $Root ".codex-plugin/plugin.json"
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.version -ne "0.1.2") {
    throw ".codex-plugin/plugin.json version must be 0.1.2 so Codex installs a visibly updated bundle"
}

$hookPath = Join-Path $Root "hooks/session-end-nudge.ps1"
$hookOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $hookPath
if ($LASTEXITCODE -ne 0) {
    throw "Codex SessionStart PowerShell hook exited with $LASTEXITCODE"
}

if ($hookOutput -notmatch "<CONTEXT-UPDATE-REMINDER>") {
    throw "Codex SessionStart hook stdout must include the literal reminder marker"
}

$hookJson = $hookOutput | ConvertFrom-Json
if ($hookJson.hookSpecificOutput.hookEventName -ne "SessionStart") {
    throw "Codex SessionStart hook must emit hookSpecificOutput.hookEventName = SessionStart"
}

if ($hookJson.hookSpecificOutput.additionalContext -notmatch "<CONTEXT-UPDATE-REMINDER>") {
    throw "Codex SessionStart hook additionalContext must include the reminder marker"
}

if ($hookJson.additionalContext -notmatch "<CONTEXT-UPDATE-REMINDER>") {
    throw "Codex SessionStart hook must also emit top-level additionalContext"
}

$gitBash = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path -LiteralPath $gitBash) {
    $bashHookPath = Join-Path $Root "hooks/session-end-nudge"
    $previousPluginRoot = $env:PLUGIN_ROOT
    $previousClaudeRoot = $env:CLAUDE_PLUGIN_ROOT
    try {
        $env:PLUGIN_ROOT = $Root
        Remove-Item Env:CLAUDE_PLUGIN_ROOT -ErrorAction SilentlyContinue
        $bashOutput = (& $gitBash $bashHookPath) -join "`n"
        if ($LASTEXITCODE -ne 0) {
            throw "Codex bash hook exited with $LASTEXITCODE"
        }
    } finally {
        $env:PLUGIN_ROOT = $previousPluginRoot
        if ($null -ne $previousClaudeRoot) {
            $env:CLAUDE_PLUGIN_ROOT = $previousClaudeRoot
        }
    }

    if ($bashOutput -notmatch "<CONTEXT-UPDATE-REMINDER>") {
        throw "Codex bash hook stdout must include the literal reminder marker"
    }

    $bashJson = $bashOutput | ConvertFrom-Json
    if ($bashJson.hookSpecificOutput.hookEventName -ne "SessionStart") {
        throw "Codex bash hook must emit hookSpecificOutput.hookEventName = SessionStart"
    }

    if ($bashJson.additionalContext -notmatch "<CONTEXT-UPDATE-REMINDER>") {
        throw "Codex bash hook must also emit top-level additionalContext"
    }
}

$hooksCodexPath = Join-Path $Root "hooks/hooks-codex.json"
$hooksCodex = Get-Content -LiteralPath $hooksCodexPath -Raw | ConvertFrom-Json
foreach ($event in @("SessionStart", "UserPromptSubmit")) {
    $entries = $hooksCodex.hooks.$event
    if ($entries.Count -lt 2) {
        throw "hooks-codex.json $event must register dual hook entries (PowerShell + bash)"
    }
    $commands = ($entries | ForEach-Object { $_.hooks } | ForEach-Object { $_.command }) -join "`n"
    if ($commands -notmatch "powershell ") {
        throw "hooks-codex.json $event must include a powershell hook entry"
    }
    if ($commands -notmatch "bash ") {
        throw "hooks-codex.json $event must include a bash hook entry"
    }
}

Write-Host "PASS Codex skill surface includes context-update-config"
