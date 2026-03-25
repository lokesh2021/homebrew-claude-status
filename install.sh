#!/usr/bin/env bash
# install.sh — Local install without Homebrew
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lokesh2021/homebrew-claude-status/main/install.sh | bash
# or locally:
#   ./install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${CLAUDE_STATUS_INSTALL_DIR:-$HOME/.local/bin}"
SETTINGS_FILE="${HOME}/.claude/settings.json"

GREEN="\033[32m"; BOLD="\033[1m"; RESET="\033[0m"; DIM="\033[2m"

step() { echo -e "${BOLD}→${RESET} $*"; }
ok()   { echo -e "${GREEN}✓${RESET} $*"; }
info() { echo -e "${DIM}  $*${RESET}"; }

echo ""
echo -e "${BOLD}Installing claude-status${RESET}"
echo ""

# ── Check dependencies ────────────────────────────────────────────────────────
step "Checking dependencies"
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not found."
  echo "Install with: brew install jq"
  exit 1
fi
ok "jq found at $(command -v jq)"

# ── Create install dir ────────────────────────────────────────────────────────
step "Installing binaries to $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

cp "$REPO_DIR/bin/claude-status" "$INSTALL_DIR/claude-status"
cp "$REPO_DIR/bin/claude-stats"  "$INSTALL_DIR/claude-stats"
chmod +x "$INSTALL_DIR/claude-status"
chmod +x "$INSTALL_DIR/claude-stats"
ok "Installed claude-status and claude-stats"

# ── Check PATH ────────────────────────────────────────────────────────────────
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
  echo ""
  echo -e "  ${BOLD}Note:${RESET} Add ${INSTALL_DIR} to your PATH:"
  echo -e "  ${DIM}echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc${RESET}"
fi

# ── Update Claude Code settings.json ─────────────────────────────────────────
step "Configuring Claude Code settings"
mkdir -p "$(dirname "$SETTINGS_FILE")"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  # Create fresh settings file
  printf '{\n  "statusCommand": "claude-status"\n}\n' > "$SETTINGS_FILE"
  ok "Created $SETTINGS_FILE"
elif command -v jq &>/dev/null; then
  # Merge into existing settings
  EXISTING=$(cat "$SETTINGS_FILE")
  echo "$EXISTING" | jq '. + {"statusCommand": "claude-status"}' > "${SETTINGS_FILE}.tmp"
  mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  ok "Updated $SETTINGS_FILE"
else
  echo ""
  echo -e "  ${BOLD}Manual step required:${RESET}"
  echo -e "  Add this to ~/.claude/settings.json:"
  echo -e '  ${DIM}{ "statusCommand": "claude-status" }${RESET}'
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Done!${RESET}"
echo ""
info "Status line is active in all new Claude Code sessions."
info "Run 'claude-stats' anytime to view your usage report."
echo ""
