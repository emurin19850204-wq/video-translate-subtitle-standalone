[CmdletBinding()]
param(
    [string]$TargetRoot = (Get-Location).Path,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$SkillName = "video-translate-subtitle"
$SourceRoot = $PSScriptRoot

if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
    throw "Skill source directory not found: $SourceRoot"
}

function Copy-SkillTo([string]$Destination) {
    if ((Test-Path -LiteralPath $Destination) -and -not $Force) {
        Write-Host "Skipped existing installation: $Destination"
        Write-Host "Use -Force to replace it."
        return
    }
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    $exclude = @(".git", "__pycache__", "*.pyc")
    Copy-Item -Path (Join-Path $SourceRoot "SKILL.md") -Destination $Destination -Force
    foreach ($folder in @("scripts", "references", "agents")) {
        $sourceFolder = Join-Path $SourceRoot $folder
        if (Test-Path -LiteralPath $sourceFolder) {
            Copy-Item -Path $sourceFolder -Destination $Destination -Recurse -Force
        }
    }
    Get-ChildItem -LiteralPath $Destination -Recurse -Force |
        Where-Object { $_.Name -eq "__pycache__" -or $_.Extension -eq ".pyc" } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Installed: $Destination"
}

$resolvedRoot = (Resolve-Path -LiteralPath $TargetRoot).Path
$claudeDestination = Join-Path $resolvedRoot ".claude\skills\$SkillName"
$codexDestination = Join-Path $resolvedRoot ".agents\skills\$SkillName"

Copy-SkillTo $claudeDestination
Copy-SkillTo $codexDestination

Write-Host ""
Write-Host "Claude Code: invoke /$SkillName or ask for English-to-Japanese video subtitles."
Write-Host "Codex: invoke `$$SkillName or ask for English-to-Japanese video subtitles."
Write-Host "Required runtime tools: ffmpeg, ffprobe, python3, and (optionally) fc-match."
