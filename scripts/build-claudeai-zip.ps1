# build-claudeai-zip.ps1
#
# PowerShell port of scripts/build-claudeai-zip.sh.
# Build a Claude.ai-compatible upload package from the skill source.
#
# Output: dist\context-update-claudeai-<version>.zip
#
# Requires: PowerShell 5.0+ (ships with Windows 10+). No external tools.
#
# This script intentionally does NOT use Compress-Archive: on Windows
# PowerShell 5.1, Compress-Archive writes ZIP entries with backslash
# separators, which violates the ZIP spec (APPNOTE.TXT 4.4.17.1 — all
# slashes MUST be '/') and causes strict readers like Claude.ai to fail
# with "Zip file contains path with invalid characters". We use
# System.IO.Compression.ZipArchive directly and force forward-slash
# entry names.
#
# Invocation (from the repo root):
#   powershell -ExecutionPolicy Bypass -File scripts\build-claudeai-zip.ps1
# or (PowerShell 7+):
#   pwsh -File scripts\build-claudeai-zip.ps1

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..')).Path
$SkillSrc  = (Resolve-Path (Join-Path $RepoRoot 'skills\context-update')).Path
$DistDir   = Join-Path $RepoRoot 'dist'
$Manifest  = Join-Path $RepoRoot '.claude-plugin\plugin.json'

if (-not (Test-Path (Join-Path $SkillSrc 'SKILL.md'))) { throw "SKILL.md missing under $SkillSrc" }
if (-not (Test-Path $Manifest))                         { throw "manifest not found at $Manifest" }

$Version = (Get-Content $Manifest -Raw | ConvertFrom-Json).version
if (-not $Version) { throw "could not read version from $Manifest" }

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
$Out = Join-Path $DistDir "context-update-claudeai-$Version.zip"
if (Test-Path $Out) { Remove-Item $Out -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ShouldSkip = {
    param($name)
    # Same junk filter as the bash script: .DS_Store, *.swp, anything inside __pycache__.
    if ($name -eq '.DS_Store')   { return $true }
    if ($name -like '*.swp')     { return $true }
    return $false
}

$Zip = [System.IO.Compression.ZipFile]::Open($Out, 'Create')
try {
    # Walk every file under the skill source.  We use $SkillSrc.Length + 1 to
    # strip the leading "<skill-src>\" prefix from FullName, then prepend
    # "context-update/" so the archive's top-level entry matches Claude.ai's
    # expected layout.
    $prefixLen = $SkillSrc.Length
    if (-not $SkillSrc.EndsWith([IO.Path]::DirectorySeparatorChar)) { $prefixLen++ }

    Get-ChildItem -LiteralPath $SkillSrc -Recurse -Force -File | ForEach-Object {
        $file = $_
        if (& $ShouldSkip $file.Name) { return }
        # Skip anything under a __pycache__ directory at any depth.
        if ($file.FullName -split '[\\/]' | Where-Object { $_ -eq '__pycache__' }) { return }

        $relative = $file.FullName.Substring($prefixLen)
        # Force forward slashes regardless of platform separator — required
        # by the ZIP spec, and the whole point of this script.
        $arcname  = 'context-update/' + ($relative -replace '\\', '/')

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
Write-Host "  3. Enable the skill on the projects/conversations where you want it."
Write-Host ""
Write-Host "Notes:"
Write-Host "  - Claude.ai does not support SessionStart hooks."
Write-Host "  - Slash-command surface varies by client version - try /context-update"
Write-Host "    first; otherwise invoke by message: 'run context-update on this conversation'."
Write-Host "  - The skill reads Project instructions, Personal preferences, and uploaded"
Write-Host "    or pasted files from the conversation context, then emits a per-file"
Write-Host "    copy-paste block you paste back into Claude.ai's UI."
