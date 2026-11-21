<#
.SYNOPSIS
    Deploys and syncs all 8 Software Factory bots into Orca Desktop (~/.orca/bots/<slug>).
.DESCRIPTION
    Creates or updates each bot folder in ~/.orca/bots/<slug> with Orca's native layout:
    bot.json (preserving existing UUID), AGENTS.md, CLAUDE.md, SOUL.md, MEMORY.md (only created
    if missing unless -ResetMemory is passed), memory/, and strictly isolated per-bot skills
    copied from ~/.agents/skills into ~/.orca/bots/<slug>/.agents/skills/.
#>
param(
    [switch]$ResetMemory,
    [string]$AgentId = "antigravity"
)

$ErrorActionPreference = "Stop"
$FactoryRoot = Split-Path -Parent $PSScriptRoot
$OrcaBotsRoot = Join-Path $env:USERPROFILE ".orca\bots"
$GlobalSkillsRoot = Join-Path $env:USERPROFILE ".agents\skills"

if (-not (Test-Path $OrcaBotsRoot)) {
    New-Item -ItemType Directory -Path $OrcaBotsRoot -Force | Out-Null
}

$BotSpecs = @(
    @{
        Slug   = "project-manager"
        Name   = "Project Manager"
        Avatar = "mascot:A1"
        Skills = @("orca-cli", "orchestration", "factory-protocol")
    },
    @{
        Slug   = "architect"
        Name   = "Architect"
        Avatar = "mascot:B1"
        Skills = @("grill-with-docs", "grill-me", "karpathy-guidelines", "factory-protocol")
    },
    @{
        Slug   = "ui-designer"
        Name   = "UI Designer"
        Avatar = "mascot:C1"
        Skills = @("frontend-design", "shadcn-vue-skilld", "orca-cli")
    },
    @{
        Slug   = "rust-dev"
        Name   = "Rust Dev"
        Avatar = "mascot:D1"
        Skills = @("orchestration", "karpathy-guidelines", "rust-axum-sqlx")
    },
    @{
        Slug   = "vue-dev"
        Name   = "Vue Dev"
        Avatar = "mascot:E1"
        Skills = @("orchestration", "karpathy-guidelines", "vue-best-practices", "vue-skilld", "vue-router-best-practices", "pinia", "shadcn-vue-skilld", "vite", "nuxt", "nuxt-seo")
    },
    @{
        Slug   = "qa-tester"
        Name   = "QA Tester"
        Avatar = "mascot:F1"
        Skills = @("orca-cli", "web-qa-checklist", "playwright-cli", "vue-testing-best-practices")
    },
    @{
        Slug   = "satpam"
        Name   = "Satpam"
        Avatar = "mascot:G1"
        Skills = @("security-audit", "rust-vue-security")
    },
    @{
        Slug   = "devops"
        Name   = "DevOps"
        Avatar = "mascot:H2"
        Skills = @("orca-cli", "coolify-deploy")
    }
)

$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$Summary = @()

foreach ($bot in $BotSpecs) {
    $slug = $bot.Slug
    $srcBotDir = Join-Path $FactoryRoot "bots\$slug"
    $dstBotDir = Join-Path $OrcaBotsRoot $slug
    $dstMemoryDir = Join-Path $dstBotDir "memory"
    $dstSkillsDir = Join-Path $dstBotDir ".agents\skills"

    New-Item -ItemType Directory -Path $dstBotDir -Force | Out-Null
    New-Item -ItemType Directory -Path $dstMemoryDir -Force | Out-Null
    New-Item -ItemType Directory -Path $dstSkillsDir -Force | Out-Null

    # 1. bot.json (preserve existing UUID if bot already exists)
    $botJsonPath = Join-Path $dstBotDir "bot.json"
    $botId = [guid]::NewGuid().ToString()
    if (Test-Path $botJsonPath) {
        try {
            $existing = Get-Content $botJsonPath -Raw | ConvertFrom-Json
            if ($existing.id) { $botId = $existing.id }
        } catch {}
    }

    $botJson = [ordered]@{
        id      = $botId
        name    = $bot.Name
        agent   = $AgentId
        avatar  = $bot.Avatar
        members = @()
    }
    [System.IO.File]::WriteAllText($botJsonPath, ($botJson | ConvertTo-Json -Depth 4), $Utf8NoBom)

    # 2. AGENTS.md & CLAUDE.md (Orca native stubs)
    $agentsMd = @"
# $($bot.Name)

You are $($bot.Name), a bot that runs in Orca. This folder is your home.

- SOUL.md says who you are and how you work. Change it only when your owner asks.
- MEMORY.md is your memory: one line per fact, details in memory/<topic>.md.
- Keep it current: date new lines, never store secrets. Remove or replace a line with ``orca bot memory forget --fact "<its words>"``; a line taken out any other way is put back.

Orca writes this file, CLAUDE.md and bot.json; edits to them are replaced.
"@
    [System.IO.File]::WriteAllText((Join-Path $dstBotDir "AGENTS.md"), $agentsMd, $Utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $dstBotDir "CLAUDE.md"), "@AGENTS.md", $Utf8NoBom)

    # 3. SOUL.md (always synced from software-factory/bots/<slug>/SOUL.md)
    Copy-Item -Force (Join-Path $srcBotDir "SOUL.md") (Join-Path $dstBotDir "SOUL.md")

    # 4. MEMORY.md (seed on first install; preserve runtime memory unless -ResetMemory)
    $dstMemFile = Join-Path $dstBotDir "MEMORY.md"
    if ($ResetMemory -or -not (Test-Path $dstMemFile)) {
        Copy-Item -Force (Join-Path $srcBotDir "MEMORY.md") $dstMemFile
    }

    # 5. Strictly sync per-bot isolated skills into .agents/skills/
    Get-ChildItem -Path $dstSkillsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if ($bot.Skills -notcontains $_.Name) {
            Remove-Item -Recurse -Force $_.FullName
        }
    }

    $missing = @()
    foreach ($skillName in $bot.Skills) {
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
        Bot           = $slug
        Name          = $bot.Name
        Agent         = $AgentId
        SkillsSynced  = ($bot.Skills.Count - $missing.Count)
        MissingSkills = ($missing -join ", ")
    }
}

Write-Host "`n==> Synced 8 Software Factory bots to $OrcaBotsRoot" -ForegroundColor Green
$Summary | Format-Table -AutoSize
