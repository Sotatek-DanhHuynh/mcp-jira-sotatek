#!/usr/bin/env bash
# ============================================================
#  MCP Jira Sotatek — Setup Script (macOS / Linux)
#  Usage: curl -fsSL https://raw.githubusercontent.com/Sotatek-DanhHuynh/mcp-jira-sotatek/master/setup.sh | bash
#  Requirements: Node.js >= 18, Claude Desktop or Claude Code CLI
# ============================================================

set -e

JIRA_BASE_URL="https://projects.plan-task.dev"
REPO_RAW="https://raw.githubusercontent.com/Sotatek-DanhHuynh/mcp-jira-sotatek/master"

echo ""
echo "================================================"
echo "   MCP Jira Sotatek Setup"
echo "================================================"
echo ""

# 1. Check Node.js
if ! command -v node >/dev/null 2>&1; then
  echo "[ERROR] Node.js is not installed. Download at: https://nodejs.org"
  exit 1
fi
echo "[OK] Node.js $(node --version)"

# 2. Determine install directory
SERVER_DIR="$HOME/.mcp-jira-sotatek"
mkdir -p "$SERVER_DIR"

echo "[...] Downloading files..."
curl -fsSL "$REPO_RAW/index.js" -o "$SERVER_DIR/index.js"
curl -fsSL "$REPO_RAW/package.json" -o "$SERVER_DIR/package.json"
echo "[OK] Files downloaded to $SERVER_DIR"

# 3. Install dependencies
echo ""
echo "[...] Installing dependencies..."
(cd "$SERVER_DIR" && npm install --silent)
echo "[OK] Dependencies installed"

# 4. Ask for token
echo ""
echo "Get your Personal Access Token at:"
echo "  $JIRA_BASE_URL -> Avatar -> Profile -> Personal Access Tokens"
echo ""
read -p "Enter your Jira Personal Access Token: " TOKEN < /dev/tty

if [ -z "$TOKEN" ]; then
  echo "[ERROR] Token cannot be empty."
  exit 1
fi

SERVER_INDEX="$SERVER_DIR/index.js"

# 5. Update Claude Desktop config
if [ "$(uname)" = "Darwin" ]; then
  CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
else
  CONFIG_PATH="$HOME/.config/Claude/claude_desktop_config.json"
fi
mkdir -p "$(dirname "$CONFIG_PATH")"
[ -f "$CONFIG_PATH" ] || echo '{}' > "$CONFIG_PATH"

node -e "
const fs = require('fs');
const path = '$CONFIG_PATH';
let cfg = {};
try { cfg = JSON.parse(fs.readFileSync(path, 'utf8')); } catch (e) {}
cfg.mcpServers = cfg.mcpServers || {};
cfg.mcpServers.jira = {
  command: 'node',
  args: ['$SERVER_INDEX'],
  env: {
    JIRA_BASE_URL: '$JIRA_BASE_URL',
    JIRA_TOKEN: '$TOKEN'
  }
};
fs.writeFileSync(path, JSON.stringify(cfg, null, 2));
"
echo "[OK] Claude Desktop config updated"

# 6. Register with Claude Code CLI
if command -v claude >/dev/null 2>&1; then
  claude mcp add -s user jira node "$SERVER_INDEX" -e "JIRA_BASE_URL=$JIRA_BASE_URL" -e "JIRA_TOKEN=$TOKEN" >/dev/null 2>&1
  echo "[OK] Claude Code CLI config updated"
else
  echo "[SKIP] Claude Code CLI not found, skipping"
  echo "       Install it with: npm install -g @anthropic-ai/claude-code"
fi

# 7. Install fix-open-issues skill into the current project (if applicable)
echo ""
echo "[...] Checking for project skill installation..."
if [ -d ".git" ] || [ -f "package.json" ]; then
  SKILL_DIR=".claude/skills/fix-open-issues"
  mkdir -p "$SKILL_DIR"
  curl -fsSL "$REPO_RAW/skills/fix-open-issues/SKILL.md" -o "$SKILL_DIR/SKILL.md"
  echo "[OK] Skill installed: $SKILL_DIR/SKILL.md"
else
  echo "[SKIP] Not in a project directory (no .git or package.json found)."
  echo "       To install the skill later: cd <your-project> then re-run this script."
fi

echo ""
echo "================================================"
echo "   Setup complete!"
echo "================================================"
echo ""
echo "-> Restart Claude Desktop/CLI to apply changes."
echo ""
echo "   github.com/Sotatek-DanhHuynh"
echo ""
