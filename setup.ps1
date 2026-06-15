# ============================================================
#  MCP Jira Sotatek — Setup Script
#  Cach 1: Right-click -> "Run with PowerShell" (local folder)
#  Cach 2: irm https://raw.githubusercontent.com/Sotatek-DanhHuynh/mcp-jira-sotatek/main/setup.ps1 | iex
#  Yeu cau: Node.js >= 18, Claude Desktop
# ============================================================

$ErrorActionPreference = "Stop"
$JIRA_BASE_URL = "https://projects.plan-task.dev"
$REPO_RAW = "https://raw.githubusercontent.com/Sotatek-DanhHuynh/mcp-jira-sotatek/main"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   MCP Jira Sotatek Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "[OK] Node.js $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "[LOI] Chua cai Node.js. Tai tai: https://nodejs.org" -ForegroundColor Red
    Read-Host "Nhan Enter de thoat"
    exit 1
}

# 2. Xac dinh SERVER_DIR
$localPath = $MyInvocation.MyCommand.Path
$isRemote = [string]::IsNullOrEmpty($localPath)

if ($isRemote) {
    # Chay qua irm | iex -> download files ve APPDATA
    $SERVER_DIR = "$env:APPDATA\mcp-jira-sotatek"
    Write-Host "[...] Cai dat vao: $SERVER_DIR" -ForegroundColor Yellow

    if (-not (Test-Path $SERVER_DIR)) {
        New-Item -ItemType Directory -Path $SERVER_DIR -Force | Out-Null
    }

    Write-Host "[...] Dang download files..." -ForegroundColor Yellow
    Invoke-WebRequest "$REPO_RAW/index.js"      -OutFile "$SERVER_DIR\index.js"
    Invoke-WebRequest "$REPO_RAW/package.json"  -OutFile "$SERVER_DIR\package.json"
    Write-Host "[OK] Download xong" -ForegroundColor Green
} else {
    # Chay local -> dung thu muc chua script
    $SERVER_DIR = Split-Path -Parent $localPath
    Write-Host "[OK] Dung thu muc hien tai: $SERVER_DIR" -ForegroundColor Green
}

# 3. Install dependencies
Write-Host ""
Write-Host "[...] Dang cai dependencies..." -ForegroundColor Yellow
Push-Location $SERVER_DIR
npm install --silent
Pop-Location
Write-Host "[OK] Dependencies da cai xong" -ForegroundColor Green

# 4. Nhap token
Write-Host ""
Write-Host "Lay Personal Access Token tai:" -ForegroundColor White
Write-Host "  $JIRA_BASE_URL -> Avatar -> Profile -> Personal Access Tokens" -ForegroundColor Gray
Write-Host ""
$token = Read-Host "Nhap Jira Personal Access Token cua ban"

if (-not $token) {
    Write-Host "[LOI] Token khong duoc de trong." -ForegroundColor Red
    Read-Host "Nhan Enter de thoat"
    exit 1
}

# 5. Detect Claude config path
$possiblePaths = @(
    (Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter "Claude_*" -ErrorAction SilentlyContinue |
        Select-Object -First 1 |
        ForEach-Object { "$($_.FullName)\LocalCache\Roaming\Claude\claude_desktop_config.json" }),
    "$env:APPDATA\Claude\claude_desktop_config.json"
)

$configPath = $null
foreach ($p in $possiblePaths) {
    if ($p -and (Test-Path $p)) {
        $configPath = $p
        break
    }
}

if (-not $configPath) {
    $configPath = "$env:APPDATA\Claude\claude_desktop_config.json"
    $configDir = Split-Path $configPath
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    '{}' | Set-Content $configPath -Encoding UTF8
    Write-Host "[OK] Tao moi file config tai: $configPath" -ForegroundColor Green
} else {
    Write-Host "[OK] Tim thay Claude config: $configPath" -ForegroundColor Green
}

# 6. Update config
$config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

if (-not $config.mcpServers) {
    $config | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{})
}

$jiraServer = [PSCustomObject]@{
    command = "node"
    args    = @("$SERVER_DIR\index.js")
    env     = [PSCustomObject]@{
        JIRA_BASE_URL = $JIRA_BASE_URL
        JIRA_TOKEN    = $token
    }
}

$config.mcpServers | Add-Member -MemberType NoteProperty -Name "jira" -Value $jiraServer -Force

$config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "   Setup hoan tat!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "-> Khoi dong lai Claude Desktop la xong." -ForegroundColor White
Write-Host ""
Write-Host "   github.com/Sotatek-DanhHuynh" -ForegroundColor DarkGray
Write-Host ""
Read-Host "Nhan Enter de dong"
