<#
.SYNOPSIS
    Deterministic Coolify REST API deployer and live smoke verifier for the Software Factory.
.DESCRIPTION
    Enforces QA + Security (satpam) PASS gates, provisions Coolify Managed PostgreSQL (for saas
    and service), creates or updates the Coolify GitHub App Dockerfile Application, injects
    required env vars without logging secrets, triggers deployment, polls completion, runs live
    HTTPS smoke checks, and writes .factory/DEPLOY.json.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectDir,

    [string]$EnvFile,
    [switch]$SkipGateCheck,
    [int]$DeployTimeoutSeconds = 900
)

$ErrorActionPreference = "Stop"
$FactoryRoot = Split-Path -Parent $PSScriptRoot

# 1. Load factory operator env file if present (never printed)
if (-not $EnvFile) {
    $EnvFile = Join-Path $FactoryRoot ".env.factory"
}
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $idx = $line.IndexOf("=")
            $k = $line.Substring(0, $idx).Trim()
            $v = $line.Substring($idx + 1).Trim()
            if (-not [Environment]::GetEnvironmentVariable($k)) {
                [Environment]::SetEnvironmentVariable($k, $v, "Process")
            }
        }
    }
}

function Require-Env([string]$Key) {
    $val = [Environment]::GetEnvironmentVariable($Key)
    if ([string]::IsNullOrWhiteSpace($val)) {
        throw "Missing required operator environment variable: $Key"
    }
    return $val
}

$CoolifyBaseUrl    = (Require-Env "COOLIFY_BASE_URL").TrimEnd("/")
$CoolifyToken      = Require-Env "COOLIFY_API_TOKEN"
$ServerUuid        = Require-Env "COOLIFY_SERVER_UUID"
$ProjectUuid       = Require-Env "COOLIFY_PROJECT_UUID"
$GithubAppUuid     = Require-Env "COOLIFY_GITHUB_APP_UUID"
$FactoryBaseDomain = Require-Env "FACTORY_BASE_DOMAIN"
$EnvName           = [Environment]::GetEnvironmentVariable("COOLIFY_ENVIRONMENT_NAME")
if ([string]::IsNullOrWhiteSpace($EnvName)) { $EnvName = "production" }

$Headers = @{
    Authorization  = "Bearer $CoolifyToken"
    "Content-Type" = "application/json"
    Accept         = "application/json"
}

function Invoke-Coolify {
    param([string]$Method, [string]$Path, [object]$Body = $null)
    $uri = "$CoolifyBaseUrl/api/v1$Path"
    if ($null -ne $Body) {
        $json = $Body | ConvertTo-Json -Depth 10 -Compress
        return Invoke-RestMethod -Method $Method -Uri $uri -Headers $Headers -Body $json
    }
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $Headers
}

function New-HexSecret([int]$Bytes = 32) {
    $buf = New-Object byte[] $Bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($buf)
    return ([System.BitConverter]::ToString($buf)).Replace("-", "").ToLowerInvariant()
}

# 2. Validate project state & mandatory QA + Satpam PASS gates
$StatePath = Join-Path $ProjectDir ".factory\PROJECT_STATE.json"
if (-not (Test-Path $StatePath)) {
    throw "Missing .factory/PROJECT_STATE.json in $ProjectDir"
}
$State = Get-Content $StatePath -Raw | ConvertFrom-Json
$Slug = $State.project_slug
$ProjectType = $State.project_type

if (-not $SkipGateCheck) {
    $QaPath  = Join-Path $ProjectDir ".factory\QA_REPORT.md"
    $SecPath = Join-Path $ProjectDir ".factory\SECURITY_REPORT.md"
    if (-not (Test-Path $QaPath) -or -not ((Get-Content $QaPath -Raw) -match 'Verdict:\s*`?PASS`?')) {
        throw "Deployment blocked: .factory/QA_REPORT.md does not show Verdict: PASS"
    }
    if (-not (Test-Path $SecPath) -or -not ((Get-Content $SecPath -Raw) -match 'Verdict:\s*`?PASS`?')) {
        throw "Deployment blocked: .factory/SECURITY_REPORT.md does not show Verdict: PASS"
    }
}

$RepoUrl = (git -C $ProjectDir remote get-url origin).Trim()
$CommitSha = (git -C $ProjectDir rev-parse HEAD).Trim()
$RepoPath = ($RepoUrl -replace '^https://github\.com/', '' -replace '\.git$', '')
$LiveUrl = "https://$Slug.$FactoryBaseDomain"
$HealthPath = if ($ProjectType -eq "landing") { "/" } else { "/api/health" }
$HealthUrl = "$LiveUrl$HealthPath"

# Push main before triggering Coolify deploy
Write-Host "==> Pushing main branch ($CommitSha)..." -ForegroundColor Cyan
git -C $ProjectDir push origin main

# Load existing DEPLOY.json if re-deploying
$DeployPath = Join-Path $ProjectDir ".factory\DEPLOY.json"
$Existing = if (Test-Path $DeployPath) { Get-Content $DeployPath -Raw | ConvertFrom-Json } else { $null }
$DbUuid = if ($Existing) { $Existing.coolify_db_uuid } else { $null }
$AppUuid = if ($Existing) { $Existing.coolify_app_uuid } else { $null }
$InternalDbUrl = $null

# 3. Provision Coolify Managed PostgreSQL (saas & service only)
if (($ProjectType -eq "saas" -or $ProjectType -eq "service") -and [string]::IsNullOrWhiteSpace($DbUuid)) {
    Write-Host "==> Provisioning Coolify Managed PostgreSQL for $Slug..." -ForegroundColor Cyan
    $dbRes = Invoke-Coolify -Method POST -Path "/databases/postgresql" -Body @{
        server_uuid      = $ServerUuid
        project_uuid     = $ProjectUuid
        environment_name = $EnvName
        name             = "$Slug-db"
        image            = "postgres:16-alpine"
        postgres_db      = ($Slug -replace '-', '_')
        postgres_user    = "app"
        instant_deploy   = $true
    }
    $DbUuid = $dbRes.uuid

    # Poll until PostgreSQL is running and internal_db_url is ready
    $deadline = (Get-Date).AddSeconds(180)
    do {
        Start-Sleep -Seconds 5
        $dbInfo = Invoke-Coolify -Method GET -Path "/databases/$DbUuid"
        $InternalDbUrl = $dbInfo.internal_db_url
        if ($dbInfo.status -match "running" -and -not [string]::IsNullOrWhiteSpace($InternalDbUrl)) {
            break
        }
    } while ((Get-Date) -lt $deadline)

    if ([string]::IsNullOrWhiteSpace($InternalDbUrl)) {
        throw "Timed out waiting for Coolify PostgreSQL ($DbUuid) to expose internal_db_url"
    }
}

# 4. Provision Coolify GitHub App Dockerfile Application
$IsNewApp = [string]::IsNullOrWhiteSpace($AppUuid)
if ($IsNewApp) {
    Write-Host "==> Creating Coolify Application ($LiveUrl)..." -ForegroundColor Cyan
    $appRes = Invoke-Coolify -Method POST -Path "/applications/private-github-app" -Body @{
        project_uuid         = $ProjectUuid
        server_uuid          = $ServerUuid
        environment_name     = $EnvName
        github_app_uuid      = $GithubAppUuid
        git_repository       = $RepoPath
        git_branch           = "main"
        build_pack           = "dockerfile"
        ports_exposes        = "8080"
        name                 = $Slug
        domains              = $LiveUrl
        health_check_enabled = $true
        health_check_path    = $HealthPath
        instant_deploy       = $false
    }
    $AppUuid = $appRes.uuid

    # Inject required environment variables (never printed)
    Write-Host "==> Configuring environment variables in Coolify..." -ForegroundColor Cyan
    $EnvVars = @(
        @{ key = "PORT"; value = "8080"; is_build_time = $false },
        @{ key = "APP_URL"; value = $LiveUrl; is_build_time = $false },
        @{ key = "RUST_LOG"; value = "info"; is_build_time = $false }
    )
    if ($ProjectType -eq "landing") {
        $EnvVars += @{ key = "NUXT_PUBLIC_SITE_URL"; value = $LiveUrl; is_build_time = $true }
        $EnvVars += @{ key = "NUXT_PUBLIC_SITE_NAME"; value = $State.project_name; is_build_time = $true }
    } else {
        $EnvVars += @{ key = "DATABASE_URL"; value = $InternalDbUrl; is_build_time = $false }
        if ($ProjectType -eq "saas") {
            $EnvVars += @{ key = "JWT_SECRET"; value = (New-HexSecret 32); is_build_time = $false }
        }
    }

    foreach ($ev in $EnvVars) {
        Invoke-Coolify -Method POST -Path "/applications/$AppUuid/envs" -Body $ev | Out-Null
    }
}

# 5. Trigger Deployment & Poll Status
Write-Host "==> Triggering Coolify deployment for app $AppUuid..." -ForegroundColor Cyan
$deployRes = Invoke-Coolify -Method GET -Path "/deploy?uuid=$AppUuid&force=true"
$DeployUuid = $deployRes.deployments[0].deployment_uuid

$deadline = (Get-Date).AddSeconds($DeployTimeoutSeconds)
$FinalStatus = "in_progress"
do {
    Start-Sleep -Seconds 10
    $statusRes = Invoke-Coolify -Method GET -Path "/deployments/$DeployUuid"
    $FinalStatus = $statusRes.status
    Write-Host "  Deployment status: $FinalStatus"
    if ($FinalStatus -in @("finished", "failed", "cancelled")) {
        break
    }
} while ((Get-Date) -lt $deadline)

if ($FinalStatus -ne "finished") {
    Write-Host "`n==> Coolify deployment failed (status: $FinalStatus). Log tail:" -ForegroundColor Red
    if ($statusRes.logs) {
        $logText = ($statusRes.logs | Out-String)
        $lines = $logText -split "`n"
        ($lines | Select-Object -Last 60) -join "`n"
    }
    throw "Coolify deployment $DeployUuid did not finish cleanly (status: $FinalStatus)"
}

# 6. Live HTTPS Smoke Test
Write-Host "==> Running live HTTPS smoke test against $HealthUrl..." -ForegroundColor Cyan
$SmokePass = $false
$HttpCode = 0
$DbConnected = $null

for ($attempt = 1; $attempt -le 6; $attempt++) {
    try {
        $resp = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 15
        $HttpCode = [int]$resp.StatusCode
        if ($HttpCode -eq 200) {
            if ($ProjectType -ne "landing") {
                $jsonBody = $resp.Content | ConvertFrom-Json
                $DbConnected = ($jsonBody.db -eq "ok")
                $SmokePass = ($jsonBody.status -eq "ok" -and $DbConnected)
            } else {
                $SmokePass = $true
            }
            if ($SmokePass) { break }
        }
    } catch {
        Write-Host "  Smoke attempt $attempt failed, retrying in 5s..."
    }
    Start-Sleep -Seconds 5
}

$NowIso = (Get-Date).ToUniversalTime().ToString("o")
$DeployRecord = [ordered]@{
    project_slug         = $Slug
    project_type         = $ProjectType
    repo_url             = $RepoUrl
    deployed_commit      = $CommitSha
    coolify_project_uuid = $ProjectUuid
    coolify_app_uuid     = $AppUuid
    coolify_db_uuid      = $DbUuid
    live_url             = $LiveUrl
    health_url           = $HealthUrl
    smoke_test           = [ordered]@{
        status                  = if ($SmokePass) { "PASS" } else { "FAIL" }
        http_code               = $HttpCode
        db_connected            = $DbConnected
        browser_screenshot_path = $null
        checked_at              = $NowIso
    }
    deployed_at          = $NowIso
}

[System.IO.File]::WriteAllText(
    $DeployPath,
    ($DeployRecord | ConvertTo-Json -Depth 6) + "`n",
    [System.Text.UTF8Encoding]::new($false)
)

if (-not $SmokePass) {
    throw "Live smoke test FAILED against $HealthUrl (HTTP $HttpCode). See $DeployPath"
}

Write-Host "`n==> Deployment & smoke test PASSED: $LiveUrl" -ForegroundColor Green
$DeployRecord | ConvertTo-Json -Depth 6
