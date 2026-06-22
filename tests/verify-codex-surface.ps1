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

$launcherPath = Join-Path $Root "hooks/codex-launcher.cmd"
$launcherOutput = & cmd /c $launcherPath
if ($LASTEXITCODE -ne 0) {
    throw "Codex launcher Windows branch exited with $LASTEXITCODE"
}

if ($launcherOutput -notmatch "<CONTEXT-UPDATE-REMINDER>") {
    throw "Codex launcher Windows branch stdout must include the literal reminder marker"
}

$gitBash = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path -LiteralPath $gitBash) {
    $previousPluginRoot = $env:PLUGIN_ROOT
    try {
        $env:PLUGIN_ROOT = $Root
        $bashOutput = (& $gitBash $launcherPath) -join "`n"
        if ($LASTEXITCODE -ne 0) {
            throw "Codex launcher bash branch exited with $LASTEXITCODE"
        }
    } finally {
        $env:PLUGIN_ROOT = $previousPluginRoot
    }

    if ($bashOutput -notmatch "<CONTEXT-UPDATE-REMINDER>") {
        throw "Codex launcher bash branch stdout must include the literal reminder marker"
    }

    $bashJson = $bashOutput | ConvertFrom-Json
    if ($bashJson.hookSpecificOutput.hookEventName -ne "SessionStart") {
        throw "Codex launcher bash branch must emit hookSpecificOutput.hookEventName = SessionStart"
    }
}

Write-Host "PASS Codex skill surface includes context-update-config"
