<#
.SYNOPSIS
    Installs external, Orca built-in, and custom local skills for the Autonomous Software Factory.
.DESCRIPTION
    Installs the verified external skills referenced in config/skills.yaml and links/copies
    this repository's custom local skills into ~/.agents/skills so Orca Desktop bots can load them.
.PARAMETER IncludeOptional
    Also prints search hints / installs optional framework skills (Vue, Nuxt, Tailwind, Playwright).
.PARAMETER DryRun
    Prints the commands that would be executed without modifying the system.
#>
param(
    [switch]$IncludeOptional,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$FactoryRoot = Split-Path -Parent $PSScriptRoot
$UserSkillsDir = Join-Path $env:USERPROFILE ".agents\skills"

function Invoke-Step {
    param([string]$Label, [scriptblock]$Action, [string]$Preview)
    Write-Host "`n==> $Label" -ForegroundColor Cyan
    if ($DryRun) {
        Write-Host "  [DRY-RUN] $Preview" -ForegroundColor Yellow
    } else {
        & $Action
    }
}

Write-Host "Software Factory Skill Installer" -ForegroundColor Green
Write-Host "Factory Root : $FactoryRoot"
Write-Host "Target Skills: $UserSkillsDir"

# 1. Orca Built-in Skills (requires Orca CLI)
Invoke-Step -Label "Update / verify Orca built-in skills (orca-cli, orchestration)" `
    -Preview "orca skills update" `
    -Action {
        if (Get-Command orca -ErrorAction SilentlyContinue) {
            orca skills update
        } else {
            Write-Warning "'orca' CLI not found on PATH. Ensure Orca Desktop CLI is installed."
        }
    }

# 2. Required External Skills
$ExternalSkills = @(
    @{ Name = "grill-with-docs (architect)";     Cmd = "npx -y skills add mattpocock/skills --skill grill-with-docs --global -y" },
    @{ Name = "grill-me (architect optional)";   Cmd = "npx -y skills add mattpocock/skills --skill grill-me --global -y" },
    @{ Name = "frontend-design (ui-designer)";   Cmd = "npx -y skills add https://github.com/anthropics/skills --skill frontend-design --global -y" },
    @{ Name = "security-audit (satpam)";         Cmd = "npx -y skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global -y" },
    @{ Name = "karpathy-guidelines (devs+arch)"; Cmd = "npx -y skills add multica-ai/andrej-karpathy-skills --skill karpathy-guidelines --global -y" }
)

foreach ($skill in $ExternalSkills) {
    $cmd = $skill.Cmd
    Invoke-Step -Label "Install external skill: $($skill.Name)" `
        -Preview $cmd `
        -Action {
            Invoke-Expression $cmd
        }
}

# 3. Copy Custom Local Factory Skills into ~/.agents/skills
$LocalSkills = @(
    "factory-protocol",
    "rust-axum-sqlx",
    "web-qa-checklist",
    "rust-vue-security",
    "coolify-deploy"
)

if (-not $DryRun -and -not (Test-Path $UserSkillsDir)) {
    New-Item -ItemType Directory -Path $UserSkillsDir -Force | Out-Null
}

foreach ($localName in $LocalSkills) {
    $src = Join-Path $FactoryRoot "skills\$localName"
    $dst = Join-Path $UserSkillsDir $localName
    Invoke-Step -Label "Install custom local skill: $localName" `
        -Preview "Copy-Item -Recurse -Force '$src' '$dst'" `
        -Action {
            if (Test-Path $dst) {
                Remove-Item -Recurse -Force $dst
            }
            Copy-Item -Recurse -Force $src $dst
            Write-Host "  Installed to $dst" -ForegroundColor Green
        }
}

if ($IncludeOptional) {
    Write-Host "`n==> Optional Framework Skills Discovery" -ForegroundColor Magenta
    Write-Host "Run these commands to pick your preferred community skills for vue-dev, ui-designer, and qa-tester:"
    Write-Host "  npx skills find vue"
    Write-Host "  npx skills find nuxt"
    Write-Host "  npx skills find shadcn-vue"
    Write-Host "  npx skills find tailwind"
    Write-Host "  npx skills find playwright"
}

Write-Host "`nDone! Verify installed skills with: ls `"$UserSkillsDir`"" -ForegroundColor Green
