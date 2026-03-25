class ClaudeStatus < Formula
  desc "Claude Code status line with live token tracking and usage analytics"
  homepage "https://github.com/lokesh2021/homebrew-claude-status"
  # Update url and sha256 after creating a GitHub release tag
  url "https://github.com/lokesh2021/homebrew-claude-status/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "fd6e0acebbab9ec706a532f4c185f6d649380ac2c9135c12b63ed5e52edccc53"
  license "MIT"
  version "1.1.0"

  depends_on "jq"

  def install
    bin.install "bin/claude-status"
    bin.install "bin/claude-stats"
    bin.install "bin/claude-blink"
  end

  def caveats
    <<~EOS
      To activate the status line and input-waiting alert in Claude Code,
      add the following to ~/.claude/settings.json:

        {
          "statusCommand": "claude-status",
          "hooks": {
            "Stop":            [{"hooks": [{"type": "command", "command": "/opt/homebrew/bin/claude-blink"}]}],
            "UserPromptSubmit":[{"hooks": [{"type": "command", "command": "/opt/homebrew/bin/claude-blink --stop"}]}],
            "PreToolUse":      [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": "/opt/homebrew/bin/claude-blink"}]}],
            "PostToolUse":     [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": "/opt/homebrew/bin/claude-blink --stop"}]}]
          }
        }

      Then start a new Claude Code session.  You should see a status line like:

        ⎇ main  ·  your-username  ·  sonnet-4-6  ·  $0.0012  ·  ↑5k ↓2k  ·  ctx [█░░░░░░░░░] 12%

      The terminal title will blink ("⏳ Waiting — Claude Code") whenever
      Claude finishes a response and is waiting for your input.

      View your usage statistics anytime:

        claude-stats           — today + week + month summary
        claude-stats today     — today only
        claude-stats week      — last 7 days
        claude-stats month     — this calendar month
        claude-stats history   — last 20 sessions
        claude-stats all       — all-time totals

      Data is stored in: ~/.local/share/claude-status/data/
    EOS
  end

  test do
    # Test that the status script handles valid JSON input correctly
    test_input = '{"model":{"display_name":"claude-sonnet-4-6"},"cost":{"total_cost_usd":0.0123,"total_duration_ms":5000},"context_window":{"used_percentage":15,"total_input_tokens":5000,"total_output_tokens":1000},"session_id":"test-session-123"}'
    output = shell_output("echo '#{test_input}' | #{bin}/claude-status")
    assert_match "$0.0123", output

    # Test that claude-stats help works
    system "#{bin}/claude-stats", "--help"
  end
end
