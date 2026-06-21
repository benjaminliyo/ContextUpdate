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
if ($manifest.version -ne "0.1.1") {
    throw ".codex-plugin/plugin.json version must be 0.1.1 so Codex installs a visibly updated bundle"
}

Write-Host "PASS Codex skill surface includes context-update-config"
