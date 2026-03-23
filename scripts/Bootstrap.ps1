<#
.SYNOPSIS
    Bootstraps a new meta-repository from the meta-repo module template.

.DESCRIPTION
    Copies the meta-repo module files to a target directory, creating a
    ready-to-use spec-driven meta-repository with AI tool integrations.

    Skips module-only files (README.md, WORKFLOW.md, scripts/) that are
    documentation for the module itself, not part of the bootstrapped output.

.PARAMETER TargetPath
    Target directory for the new meta-repo (required).

.PARAMETER Tools
    Array of AI tools to include. Valid values: "claude-code", "copilot", "cursor"
    Defaults to all three if not specified.

.PARAMETER ProjectName
    Replace [Project Name] placeholders with this name.

.PARAMETER DryRun
    If specified, shows what would be done without making any changes.

.EXAMPLE
    # Bootstrap with all tools
    .\Bootstrap.ps1 -TargetPath ~\projects\my-meta-repo

.EXAMPLE
    # Bootstrap with specific tools and project name
    .\Bootstrap.ps1 -TargetPath ~\projects\my-meta-repo `
        -Tools @("claude-code", "copilot") `
        -ProjectName "My Project"

.EXAMPLE
    # Preview what would be copied
    .\Bootstrap.ps1 -TargetPath ~\projects\my-meta-repo -DryRun

.NOTES
    File Name      : Bootstrap.ps1
    Prerequisite   : PowerShell 5.1 or later
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,

    [Parameter(Mandatory=$false)]
    [ValidateSet("claude-code", "copilot", "cursor")]
    [string[]]$Tools = @("claude-code", "copilot", "cursor"),

    [Parameter(Mandatory=$false)]
    [string]$ProjectName,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve module root from script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleRoot = Split-Path -Parent $ScriptDir

# Tracking
$FileCount = 0

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-BootstrapWarning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-BootstrapError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-ShouldSkipFile {
    param([string]$RelativePath)

    # Skip module-only files
    if ($RelativePath -eq "README.md" -or $RelativePath -eq "WORKFLOW.md") {
        return $true
    }
    if ($RelativePath -like "scripts*") {
        return $true
    }

    # Skip tool dirs based on -Tools selection
    if ($Tools -notcontains "claude-code" -and $RelativePath -like ".claude*") {
        return $true
    }
    if ($Tools -notcontains "copilot" -and $RelativePath -like ".github*") {
        return $true
    }
    if ($Tools -notcontains "cursor" -and $RelativePath -like ".cursor*") {
        return $true
    }

    return $false
}

function Copy-BootstrapFile {
    param(
        [string]$SourcePath,
        [string]$DestPath
    )

    $destDir = Split-Path -Parent $DestPath

    if ($DryRun) {
        Write-Info "Would copy: $SourcePath -> $DestPath"
        $script:FileCount++
        return
    }

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    Copy-Item -Path $SourcePath -Destination $DestPath -Force
    $script:FileCount++
}

# ============================================================================
# Main Script Logic
# ============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Meta-Repo Bootstrap" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-BootstrapWarning "DRY RUN MODE - No changes will be made"
    Write-Host ""
}

Write-Info "Source module: $ModuleRoot"
Write-Info "Target path: $TargetPath"
Write-Info "Tools: $($Tools -join ', ')"
if ($ProjectName) {
    Write-Info "Project name: $ProjectName"
}
Write-Host ""

# ============================================================================
# Create Target Directory
# ============================================================================

if (-not $DryRun) {
    if (-not (Test-Path $TargetPath)) {
        New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
    }
}

# ============================================================================
# Copy Files
# ============================================================================

Write-Host "--- Copying Files ---" -ForegroundColor Yellow

$allFiles = Get-ChildItem -Path $ModuleRoot -Recurse -File

foreach ($file in $allFiles) {
    $relativePath = $file.FullName.Substring($ModuleRoot.Length + 1)
    # Normalize path separators
    $relativePath = $relativePath -replace '\\', '/'

    if (Test-ShouldSkipFile -RelativePath $relativePath) {
        continue
    }

    $destFile = Join-Path $TargetPath $relativePath
    Copy-BootstrapFile -SourcePath $file.FullName -DestPath $destFile
}

Write-Host ""

# ============================================================================
# Create Empty Spec Directories with .gitkeep
# ============================================================================

Write-Host "--- Creating Spec Directories ---" -ForegroundColor Yellow

$specTypes = @("bug", "chore", "design", "feature", "planning")

foreach ($specType in $specTypes) {
    $specDir = Join-Path $TargetPath "specs/$specType"
    $gitkeep = Join-Path $specDir ".gitkeep"

    if ($DryRun) {
        if (-not (Test-Path $gitkeep)) {
            Write-Info "Would create: specs/$specType/.gitkeep"
        }
    }
    else {
        if (-not (Test-Path $specDir)) {
            New-Item -ItemType Directory -Path $specDir -Force | Out-Null
        }
        if (-not (Test-Path $gitkeep)) {
            New-Item -ItemType File -Path $gitkeep -Force | Out-Null
            Write-Info "Created: specs/$specType/.gitkeep"
        }
    }
}

Write-Host ""

# ============================================================================
# Replace Placeholders
# ============================================================================

if ($ProjectName) {
    Write-Host "--- Replacing Placeholders ---" -ForegroundColor Yellow

    $placeholderFiles = @(
        (Join-Path $TargetPath "AGENTS.md"),
        (Join-Path $TargetPath "CLAUDE.md"),
        (Join-Path $TargetPath "project/README.md")
    )

    # Add .yaml files from project/
    $projectDir = Join-Path $TargetPath "project"
    if (Test-Path $projectDir) {
        $yamlFiles = Get-ChildItem -Path $projectDir -Filter "*.yaml" -File -ErrorAction SilentlyContinue
        foreach ($yamlFile in $yamlFiles) {
            $placeholderFiles += $yamlFile.FullName
        }
    }

    # Add template files
    $templatesDir = Join-Path $TargetPath "docs/templates"
    if (Test-Path $templatesDir) {
        $templateFiles = Get-ChildItem -Path $templatesDir -File -ErrorAction SilentlyContinue
        foreach ($tmplFile in $templateFiles) {
            $placeholderFiles += $tmplFile.FullName
        }
    }

    foreach ($targetFile in $placeholderFiles) {
        if (Test-Path $targetFile) {
            $content = Get-Content $targetFile -Raw -ErrorAction SilentlyContinue
            if ($content -and $content -match '\[Project Name\]') {
                if ($DryRun) {
                    $displayPath = $targetFile.Substring($TargetPath.Length + 1)
                    Write-Info "Would replace [Project Name] in: $displayPath"
                }
                else {
                    $newContent = $content -replace '\[Project Name\]', $ProjectName
                    Set-Content -Path $targetFile -Value $newContent -NoNewline -Encoding UTF8
                    $displayPath = $targetFile.Substring($TargetPath.Length + 1)
                    Write-Success "Replaced [Project Name] in: $displayPath"
                }
            }
        }
    }

    Write-Host ""
}

# ============================================================================
# Initialize Git Repository
# ============================================================================

if (-not $DryRun) {
    $gitDir = Join-Path $TargetPath ".git"
    if (-not (Test-Path $gitDir)) {
        Write-Host "--- Initializing Git Repository ---" -ForegroundColor Yellow
        Push-Location $TargetPath
        try {
            git init
        }
        finally {
            Pop-Location
        }
        Write-Host ""
    }
}

# ============================================================================
# Summary
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Bootstrap Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Target path: $TargetPath" -ForegroundColor White
Write-Host "Tools installed: $($Tools -join ', ')" -ForegroundColor White
Write-Host "Files copied: $FileCount" -ForegroundColor White
if ($ProjectName) {
    Write-Host "Project name: $ProjectName" -ForegroundColor White
}
Write-Host ""

if ($DryRun) {
    Write-BootstrapWarning "This was a dry run. No files were actually copied."
}
else {
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Edit AGENTS.md - fill in the 'Your Project' and 'Communication Style' sections" -ForegroundColor White
    Write-Host "2. Edit project/project-repositories.yaml - add your repositories" -ForegroundColor White
    Write-Host "3. Start creating specs with /new-spec (Claude Code) or equivalent" -ForegroundColor White
    Write-Host ""
    Write-Success "Bootstrap complete!"
}
