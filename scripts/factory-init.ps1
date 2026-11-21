<#
.SYNOPSIS
    Deterministic repository scaffolder for the Autonomous Software Factory.
.DESCRIPTION
    Clones the selected Golden Template into projects/<Slug>, substitutes project placeholders,
    copies canonical .factory/ templates, initializes git (main + develop), optionally creates a
    private GitHub repository via `gh`, and registers the repo in Orca Desktop (`orca repo add`).
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9-]+$')]
    [string]$Slug,

    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [ValidateSet('saas', 'landing', 'service')]
    [string]$Type,

    [string]$GitHubOwner = "afdil",
    [string]$TargetParentDir,
    [switch]$LocalOnly,
    [switch]$SkipOrcaRegister
)

$ErrorActionPreference = "Stop"
$FactoryRoot = Split-Path -Parent $PSScriptRoot

$TemplateMap = @{
    saas    = "tpl-saas-rust-vue"
    landing = "tpl-landing-nuxt"
    service = "tpl-service-rust"
}

$TemplateName = $TemplateMap[$Type]
$TemplateDir = Join-Path $FactoryRoot "templates\$TemplateName"
if (-not (Test-Path $TemplateDir)) {
    throw "Golden template not found at $TemplateDir"
}

if (-not $TargetParentDir) {
    $TargetParentDir = Join-Path $FactoryRoot "projects"
}
if (-not (Test-Path $TargetParentDir)) {
    New-Item -ItemType Directory -Path $TargetParentDir -Force | Out-Null
}

$ProjectDir = Join-Path $TargetParentDir $Slug
if (Test-Path $ProjectDir) {
    throw "Target project directory already exists: $ProjectDir"
}

Write-Host "==> Scaffolding '$Name' ($Slug) from $TemplateName..." -ForegroundColor Cyan
Copy-Item -Recurse -Force $TemplateDir $ProjectDir

# Replace __PROJECT_SLUG__ and __PROJECT_NAME__ placeholders in text files
$TextExtensions = @(".md", ".json", ".toml", ".ts", ".vue", ".html", ".css", ".yml", ".yaml", ".example", "")
Get-ChildItem -Path $ProjectDir -Recurse -File | ForEach-Object {
    if ($TextExtensions -contains $_.Extension.ToLowerInvariant()) {
        $content = Get-Content -Path $_.FullName -Raw
        if ($null -ne $content -and ($content.Contains("__PROJECT_SLUG__") -or $content.Contains("__PROJECT_NAME__"))) {
            $updated = $content.Replace("__PROJECT_SLUG__", $Slug).Replace("__PROJECT_NAME__", $Name)
            [System.IO.File]::WriteAllText($_.FullName, $updated, [System.Text.UTF8Encoding]::new($false))
        }
    }
}

# Write initial .factory/PROJECT_STATE.json
$StateObj = [ordered]@{
    project_slug = $Slug
    project_name = $Name
    project_type = $Type
    template     = $TemplateName
    status       = "initialized"
    created_at   = (Get-Date).ToUniversalTime().ToString("o")
}
$StatePath = Join-Path $ProjectDir ".factory\PROJECT_STATE.json"
[System.IO.File]::WriteAllText(
    $StatePath,
    ($StateObj | ConvertTo-Json -Depth 5) + "`n",
    [System.Text.UTF8Encoding]::new($false)
)

# Copy .env.example to .env for immediate local development
$EnvExample = Join-Path $ProjectDir ".env.example"
if (Test-Path $EnvExample) {
    Copy-Item $EnvExample (Join-Path $ProjectDir ".env")
}

# Initialize Git with main and develop branches
Write-Host "==> Initializing Git branches (main, develop)..." -ForegroundColor Cyan
git -C $ProjectDir init -b main | Out-Null
git -C $ProjectDir add .
git -C $ProjectDir commit -m "chore: scaffold $Slug from $TemplateName" | Out-Null
git -C $ProjectDir checkout -b develop | Out-Null

$RepoUrl = $null
if (-not $LocalOnly) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "GitHub CLI ('gh') not found. Install gh or pass -LocalOnly."
    }
    Write-Host "==> Creating private GitHub repository $GitHubOwner/$Slug..." -ForegroundColor Cyan
    gh repo create "$GitHubOwner/$Slug" --private --source $ProjectDir --remote origin --push
    git -C $ProjectDir push -u origin develop
    $RepoUrl = "https://github.com/$GitHubOwner/$Slug"
}

if (-not $SkipOrcaRegister -and (Get-Command orca -ErrorAction SilentlyContinue)) {
    Write-Host "==> Registering repository in Orca Desktop..." -ForegroundColor Cyan
    try {
        orca repo add $ProjectDir --json | Out-Null
    } catch {
        Write-Warning "Could not register repo in Orca right now (is Orca Desktop running?). Register later via: orca repo add `"$ProjectDir`""
    }
}

$Result = [ordered]@{
    project_slug = $Slug
    project_name = $Name
    project_type = $Type
    template     = $TemplateName
    project_dir  = $ProjectDir
    repo_url     = $RepoUrl
    active_branch = "develop"
}

Write-Host "`n==> Scaffolding complete!" -ForegroundColor Green
$Result | ConvertTo-Json -Depth 5
