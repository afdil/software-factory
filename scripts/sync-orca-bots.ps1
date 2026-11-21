<#
.SYNOPSIS
    Syncs SOUL.md, MEMORY.md, and isolated per-bot skills into officially registered Orca Desktop bots.
.DESCRIPTION
    Queries `orca bot list --json` so it ONLY updates bots that have been created through Orca
    Desktop's UI (never modifies Orca-managed bot.json, AGENTS.md, or CLAUDE.md, and never creates
    unregistered folders that could cause `-2` folder duplicates).
#>
param(
    [switch]$ResetMemory
)

$ErrorActionPreference = "Stop"
$FactoryRoot = Split-Path -Parent $PSScriptRoot
$OrcaBotsRoot = Join-Path $env:USERPROFILE ".orca\bots"
$GlobalSkillsRoot = Join-Path $env:USERPROFILE ".agents\skills"

$BotSpecs = @(
    @{
        Slug   = "project-manager"
        Name   = "Project Manager"
        Skills = @("orca-cli", "orchestration", "factory-protocol")
    },
    @{
        Slug   = "architect"
        Name   = "Architect"
        Skills = @("grill-with-docs", "grill-me", "karpathy-guidelines", "factory-protocol")
    },
    @{
        Slug   = "ui-designer"
        Name   = "UI Designer"
        Skills = @("frontend-design", "shadcn-vue-skilld", "orca-cli")
    },
    @{
        Slug   = "rust-dev"
        Name   = "Rust Dev"
        Skills = @("orchestration", "karpathy-guidelines", "rust-axum-sqlx")
    },
    @{
        Slug   = "vue-dev"
        Name   = "Vue Dev"
        Skills = @("orchestration", "karpathy-guidelines", "vue-best-practices", "vue-skilld", "vue-router-best-practices", "pinia", "shadcn-vue-skilld", "vite", "nuxt", "nuxt-seo")
    },
    @{
        Slug   = "qa-tester"
        Name   = "QA Tester"
        Skills = @("orca-cli", "web-qa-checklist", "playwright-cli", "vue-testing-best-practices")
    },
    @{
        Slug   = "satpam"
        Name   = "Satpam"
        Skills = @("security-audit", "rust-vue-security")
    },
    @{
        Slug   = "devops"
        Name   = "DevOps"
        Skills = @("orca-cli", "coolify-deploy")
    }
)

# 1. Discover officially registered bots via Orca CLI
$rawList = orca bot list --json
if ($LASTEXITCODE -ne 0) {
    throw "Failed to run 'orca bot list --json'. Make sure Orca Desktop is running."
}
$parsed = $rawList | ConvertFrom-Json
if (-not $parsed.ok) {
    throw "Orca returned an error: $($parsed.error.message)"
}

# Build map of bot.json id -> folder path on disk
$FolderById = @{}
$FolderByName = @{}
Get-ChildItem -Path $OrcaBotsRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $bj = Join-Path $_.FullName "bot.json"
    if (Test-Path $bj) {
        try {
            $meta = Get-Content $bj -Raw | ConvertFrom-Json
            if ($meta.id) { $FolderById[$meta.id] = $_.FullName }
            if ($meta.name) { $FolderByName[$meta.name.ToLowerInvariant()] = $_.FullName }
        } catch {}
    }
}

$RegisteredByName = @{}
foreach ($b in $parsed.result.bots) {
    $RegisteredByName[$b.name.ToLowerInvariant()] = $b
}

$Summary = @()

foreach ($spec in $BotSpecs) {
    $key = $spec.Name.ToLowerInvariant()
    $reg = $RegisteredByName[$key]
    if (-not $reg) {
        $Summary += [PSCustomObject]@{
            Bot          = $spec.Name
            Status       = "NOT_CREATED_IN_ORCA"
            Folder       = "-"
            SkillsSynced = 0
            Missing      = "-"
        }
        continue
    }

    $dstBotDir = $FolderById[$reg.id]
    if (-not $dstBotDir) { $dstBotDir = $FolderByName[$key] }
    if (-not $dstBotDir -or -not (Test-Path $dstBotDir)) {
        $Summary += [PSCustomObject]@{
            Bot          = $spec.Name
            Status       = "FOLDER_NOT_FOUND"
            Folder       = "-"
            SkillsSynced = 0
            Missing      = "-"
        }
        continue
    }

    $srcBotDir = Join-Path $FactoryRoot "bots\$($spec.Slug)"
    $dstSkillsDir = Join-Path $dstBotDir ".agents\skills"
    New-Item -ItemType Directory -Path $dstSkillsDir -Force | Out-Null

    # Sync SOUL.md (never touch bot.json, AGENTS.md, or CLAUDE.md)
    Copy-Item -Force (Join-Path $srcBotDir "SOUL.md") (Join-Path $dstBotDir "SOUL.md")

    # Seed MEMORY.md only if empty/default or when -ResetMemory is passed
    $dstMemFile = Join-Path $dstBotDir "MEMORY.md"
    $shouldSeedMemory = $ResetMemory -or (-not (Test-Path $dstMemFile))
    if (-not $shouldSeedMemory) {
        $existingMem = Get-Content $dstMemFile -Raw
        if ($existingMem -notmatch '(?m)^-\s+\d{4}-\d{2}-\d{2}\s+') {
            $shouldSeedMemory = $true
        }
    }
    if ($shouldSeedMemory) {
        Copy-Item -Force (Join-Path $srcBotDir "MEMORY.md") $dstMemFile
    }

    # Strictly sync isolated per-bot skills
    Get-ChildItem -Path $dstSkillsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if ($spec.Skills -notcontains $_.Name) {
            Remove-Item -Recurse -Force $_.FullName
        }
    }

    $missing = @()
    foreach ($skillName in $spec.Skills) {
        $srcSkill = Join-Path $GlobalSkillsRoot $skillName
        $dstSkill = Join-Path $dstSkillsDir $skillName
        if (-not (Test-Path $srcSkill)) {
            $missing += $skillName
            continue
        }
        if (Test-Path $dstSkill) {
            Remove-Item -Recurse -Force $dstSkill
        }
        Copy-Item -Recurse -Force $srcSkill $dstSkill
    }

    $Summary += [PSCustomObject]@{
        Bot          = $spec.Name
        Status       = "SYNCED"
        Folder       = Split-Path -Leaf $dstBotDir
        SkillsSynced = ($spec.Skills.Count - $missing.Count)
        Missing      = ($missing -join ", ")
    }
}

Write-Host "`n==> Orca Bot Sync Report" -ForegroundColor Green
$Summary | Format-Table -AutoSize
