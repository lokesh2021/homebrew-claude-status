class ClaudeStatus < Formula
  desc "Claude Code status line with live token tracking and usage analytics"
  homepage "https://github.com/lokesh2021/homebrew-claude-status"
  # Update url and sha256 after creating a GitHub release tag
  url "https://github.com/lokesh2021/homebrew-claude-status/archive/refs/tags/v1.2.1.tar.gz"
  sha256 "128ee2e915df8807495c978cb05c87c950362b4069d36ff93ba6ae15dafa8d36"
  license "MIT"
  version "1.2.1"

  depends_on "jq"

  def install
    bin.install "bin/claude-status"
    bin.install "bin/claude-stats"
  end

  def caveats
    <<~EOS
      To activate the status line in Claude Code, add the following to
      ~/.claude/settings.json:

        {
          "statusLine": {
            "type": "command",
            "command": "claude-status"
          }
        }

      Then start a new Claude Code session. You should see a status line like:

        ⎇ main  ·  your-username  ·  sonnet-4-6  ·  $0.0012  ·  ↑5k ↓2k  ·  ctx [█░░░░░░░░░] 12%

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
