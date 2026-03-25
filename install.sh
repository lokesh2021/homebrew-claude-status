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
cp "$REPO_DIR/bin/claude-blink"  "$INSTALL_DIR/claude-blink"
chmod +x "$INSTALL_DIR/claude-status"
chmod +x "$INSTALL_DIR/claude-stats"
chmod +x "$INSTALL_DIR/claude-blink"
ok "Installed claude-status, claude-stats, and claude-blink"

# ── Check PATH ────────────────────────────────────────────────────────────────
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
  echo ""
  echo -e "  ${BOLD}Note:${RESET} Add ${INSTALL_DIR} to your PATH:"
  echo -e "  ${DIM}echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc${RESET}"
fi

# ── Update Claude Code settings.json ─────────────────────────────────────────
step "Configuring Claude Code settings"
mkdir -p "$(dirname "$SETTINGS_FILE")"

BLINK_CMD="$INSTALL_DIR/claude-blink"
BLINK_STOP_CMD="$INSTALL_DIR/claude-blink --stop"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  # Create fresh settings file with status line + all blink hooks (full paths)
  jq -n \
    --arg blink      "$BLINK_CMD" \
    --arg blink_stop "$BLINK_STOP_CMD" '{
    "statusCommand": "claude-status",
    "hooks": {
      "Stop":            [{"hooks": [{"type": "command", "command": $blink}]}],
      "UserPromptSubmit":[{"hooks": [{"type": "command", "command": $blink_stop}]}],
      "PreToolUse":      [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": $blink}]}],
      "PostToolUse":     [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": $blink_stop}]}]
    }
  }' > "$SETTINGS_FILE"
  ok "Created $SETTINGS_FILE"
elif command -v jq &>/dev/null; then
  # Merge into existing settings.
  # For each hook event: remove any stale claude-blink entries, then append the
  # fresh one with the correct full path.  Other hooks (non-claude-blink) are
  # preserved unchanged.
  EXISTING=$(cat "$SETTINGS_FILE")
  echo "$EXISTING" | jq \
    --arg blink      "$BLINK_CMD" \
    --arg blink_stop "$BLINK_STOP_CMD" '
    . + {"statusCommand": "claude-status"} |

    # Helper: strip old claude-blink entries from a hook array
    def drop_blink: map(select(
      (.hooks // []) | map(.command // "") | any(test("claude-blink")) | not
    ));

    .hooks.Stop            = ((.hooks.Stop            // []) | drop_blink) + [{"hooks": [{"type": "command", "command": $blink}]}] |
    .hooks.UserPromptSubmit= ((.hooks.UserPromptSubmit // []) | drop_blink) + [{"hooks": [{"type": "command", "command": $blink_stop}]}] |
    .hooks.PreToolUse      = ((.hooks.PreToolUse       // []) | drop_blink) + [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": $blink}]}] |
    .hooks.PostToolUse     = ((.hooks.PostToolUse      // []) | drop_blink) + [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": $blink_stop}]}]
  ' > "${SETTINGS_FILE}.tmp"
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
info "Terminal will blink when Claude is waiting for your input."
info "Run 'claude-stats' anytime to view your usage report."
echo ""
