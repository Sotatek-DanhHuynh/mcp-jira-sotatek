# ============================================================
#  MCP Jira Sotatek — Setup Script
#  Cach 1: Right-click -> "Run with PowerShell" (thu muc local)
#  Cach 2: irm https://raw.githubusercontent.com/Sotatek-DanhHuynh/mcp-jira-sotatek/master/setup.ps1 | iex
#  Yeu cau: Node.js >= 18, Claude Desktop hoac Claude Code CLI
# ============================================================

$ErrorActionPreference = "Stop"
$JIRA_BASE_URL = "https://projects.plan-task.dev"
$REPO_RAW = "https://raw.githubusercontent.com/Sotatek-DanhHuynh/mcp-jira-sotatek/master"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   MCP Jira Sotatek Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Kiem tra Node.js
try {
    $nodeVersion = node --version
    Write-Host "[OK] Node.js $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js is not installed. Download at: https://nodejs.org" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 2. Xac dinh thu muc cai dat
$localPath = $MyInvocation.MyCommand.Path
$isRemote = [string]::IsNullOrEmpty($localPath)

if ($isRemote) {
    # Chay qua irm | iex -> download files ve APPDATA
    $SERVER_DIR = "$env:APPDATA\mcp-jira-sotatek"
    Write-Host "[...] Installing to: $SERVER_DIR" -ForegroundColor Yellow

    if (-not (Test-Path $SERVER_DIR)) {
        New-Item -ItemType Directory -Path $SERVER_DIR -Force | Out-Null
    }

    Write-Host "[...] Downloading files..." -ForegroundColor Yellow
    Invoke-WebRequest "$REPO_RAW/index.js"      -OutFile "$SERVER_DIR\index.js"
    Invoke-WebRequest "$REPO_RAW/package.json"  -OutFile "$SERVER_DIR\package.json"
    Write-Host "[OK] Files downloaded" -ForegroundColor Green
} else {
    # Chay local -> dung thu muc chua script
    $SERVER_DIR = Split-Path -Parent $localPath
    Write-Host "[OK] Using local directory: $SERVER_DIR" -ForegroundColor Green
}

# 3. Cai dependencies
Write-Host ""
Write-Host "[...] Installing dependencies..." -ForegroundColor Yellow
Push-Location $SERVER_DIR
npm.cmd install --silent
Pop-Location
Write-Host "[OK] Dependencies installed" -ForegroundColor Green

# 4. Nhap token
Write-Host ""
Write-Host "Get your Personal Access Token at:" -ForegroundColor White
Write-Host "  $JIRA_BASE_URL -> Avatar -> Profile -> Personal Access Tokens" -ForegroundColor Gray
Write-Host ""
$token = Read-Host "Enter your Jira Personal Access Token"

if (-not $token) {
    Write-Host "[ERROR] Token cannot be empty." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$serverIndex = "$SERVER_DIR\index.js"

# 5. Cap nhat Claude Desktop config (claude_desktop_config.json)
$serverIndexJson = $serverIndex -replace '\\', '\\'
$mcpBlock = "  ""mcpServers"": {`n    ""jira"": {`n      ""command"": ""node"",`n      ""args"": [""$serverIndexJson""],`n      ""env"": {`n        ""JIRA_BASE_URL"": ""$JIRA_BASE_URL"",`n        ""JIRA_TOKEN"": ""$token""`n      }`n    }`n  }"

$possiblePaths = @(
    (Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter "Claude_*" -ErrorAction SilentlyContinue |
        Select-Object -First 1 |
        ForEach-Object { "$($_.FullName)\LocalCache\Roaming\Claude\claude_desktop_config.json" }),
    "$env:APPDATA\Claude\claude_desktop_config.json"
)

$configPath = $null
foreach ($p in $possiblePaths) {
    if ($p -and (Test-Path $p)) { $configPath = $p; break }
}

if (-not $configPath) {
    $configPath = "$env:APPDATA\Claude\claude_desktop_config.json"
    $configDir = Split-Path $configPath
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    $noBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($configPath, '{}', $noBom)
}

$raw = Get-Content $configPath -Raw -Encoding UTF8
if ($raw -match '"mcpServers"') {
    $raw = $raw -replace '"mcpServers"\s*:\s*\{(?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*\}', $mcpBlock.TrimStart()
} else {
    $body = $raw.Trim()
    if ($body -eq '{}' -or $body -eq '{') {
        $raw = "{`n$mcpBlock`n}"
    } else {
        $raw = $body.TrimEnd('}').TrimEnd() + ",`n$mcpBlock`n}"
    }
}
$noBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($configPath, $raw, $noBom)
Write-Host "[OK] Claude Desktop config updated" -ForegroundColor Green

# 6. Dang ky voi Claude Code CLI (ghi vao ~/.claude.json, tu dong load o moi session)
try {
    $claudeCmd = Get-Command claude -ErrorAction Stop
    claude mcp add -s user jira node $serverIndex -e "JIRA_BASE_URL=$JIRA_BASE_URL" -e "JIRA_TOKEN=$token" 2>&1 | Out-Null
    Write-Host "[OK] Claude Code CLI config updated" -ForegroundColor Green
} catch {
    # Claude Code CLI chua cai -> bo qua, chi can Desktop config la du
    Write-Host "[SKIP] Claude Code CLI not found, skipping" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "   Setup complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "-> Restart Claude Desktop to apply changes." -ForegroundColor White
Write-Host ""
Write-Host "   github.com/Sotatek-DanhHuynh" -ForegroundColor DarkGray
Write-Host ""
Read-Host "Press Enter to close"
