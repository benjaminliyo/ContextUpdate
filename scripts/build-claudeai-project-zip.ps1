# build-claudeai-project-zip.ps1
#
# PowerShell port of scripts/build-claudeai-project-zip.sh.
# Build the Claude.ai-only slim variant (`context-update-project`) for
# upload to Claude.ai (web / desktop). This skill is single-layer, has
# no filesystem probes, no `.contextupdate.toml`, and emits copy-paste
# deliverables only.
#
# Output: dist\context-update-project-claudeai-<version>.zip
#
# Requires: PowerShell 5.0+ (ships with Windows 10+). No external tools.
#
# Like build-claudeai-zip.ps1, this uses System.IO.Compression.ZipArchive
# directly (not Compress-Archive) to force forward-slash entry names,
# required by the ZIP spec and Claude.ai's zip reader.
#
# Invocation (from the repo root):
#   powershell -ExecutionPolicy Bypass -File scripts\build-claudeai-project-zip.ps1
# or (PowerShell 7+):
#   pwsh -File scripts\build-claudeai-project-zip.ps1

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..')).Path
$SkillSrc  = (Resolve-Path (Join-Path $RepoRoot 'skills\context-update-project')).Path
$DistDir   = Join-Path $RepoRoot 'dist'
$Manifest  = Join-Path $RepoRoot '.claude-plugin\plugin.json'

if (-not (Test-Path (Join-Path $SkillSrc 'SKILL.md'))) { throw "SKILL.md missing under $SkillSrc" }
if (-not (Test-Path $Manifest))                         { throw "manifest not found at $Manifest" }

$Version = (Get-Content $Manifest -Raw | ConvertFrom-Json).version
if (-not $Version) { throw "could not read version from $Manifest" }

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
$Out = Join-Path $DistDir "context-update-project-claudeai-$Version.zip"
if (Test-Path $Out) { Remove-Item $Out -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ShouldSkip = {
    param($name)
    if ($name -eq '.DS_Store') { return $true }
    if ($name -like '*.swp')   { return $true }
    return $false
}

$Zip = [System.IO.Compression.ZipFile]::Open($Out, 'Create')
try {
    $prefixLen = $SkillSrc.Length
    if (-not $SkillSrc.EndsWith([IO.Path]::DirectorySeparatorChar)) { $prefixLen++ }

    Get-ChildItem -LiteralPath $SkillSrc -Recurse -Force -File | ForEach-Object {
        $file = $_
        if (& $ShouldSkip $file.Name) { return }
        if ($file.FullName -split '[\\/]' | Where-Object { $_ -eq '__pycache__' }) { return }

        $relative = $file.FullName.Substring($prefixLen)
        $arcname  = 'context-update-project/' + ($relative -replace '\\', '/')

        $entry  = $Zip.CreateEntry($arcname, [System.IO.Compression.CompressionLevel]::Optimal)
        $entryStream = $entry.Open()
        try {
            $fileStream = [System.IO.File]::OpenRead($file.FullName)
            try   { $fileStream.CopyTo($entryStream) }
            finally { $fileStream.Dispose() }
        }
        finally { $entryStream.Dispose() }
    }
}
finally {
    $Zip.Dispose()
}

Write-Host "Built: $Out"
Write-Host ""
Write-Host "Upload steps (Claude.ai):"
Write-Host "  1. Open claude.ai -> Customize (left sidebar) -> Skills."
Write-Host "  2. Upload $Out."
Write-Host "  3. Enable the skill on the Projects where you want it."
Write-Host ""
Write-Host "Notes:"
Write-Host "  - This is the Claude.ai-only slim variant."
Write-Host "  - Trigger with /context-update or by asking 'run context update'."
Write-Host "  - Deliverable is always a copy-paste block. The skill never claims"
Write-Host "    to have applied changes. You paste into Project settings yourself."
