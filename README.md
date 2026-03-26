# claude-status

Live Claude Code status line with token tracking, cost monitoring, and usage analytics.

## What it shows

```
⎇ main  ·  lokesh2021  ·  Sonnet 4.6  ·  $0.0123  ·  ↑5k ↓2k  ·  ctx [█░░░░░░░░░] 12%  ·  5h:8%  ·  2m30s
```

All data points fit on a single line when the terminal is wide enough, and automatically wrap to two lines on narrow terminals:

```
Sonnet 4.6  ·  $0.0123  ·  ↑5k ↓2k  ·  2m30s
⎇ main  ·  lokesh2021  ·  ctx [███████████████░░░░░] 75%  ·  5h:8%
```

| Field | Description |
|---|---|
| `⎇ main` | Current git branch |
| `lokesh2021` | Active GitHub account (auto-detected from `gh auth`, cached 7 days) |
| `Sonnet 4.6` | Active Claude model |
| `$0.0123` | Session cost so far (colour-coded: green → yellow → red) |
| `↑5k ↓2k` | Input / output tokens this session |
| `ctx [█░░░░░░░░░] 12%` | Context window used with progress bar (colour-coded) |
| `5h:8%` | 5-hour rate limit usage (hidden when 0%) |
| `7d:3%` | 7-day rate limit usage (hidden when 0%) |
| `2m30s` | Session wall-clock duration |

## Install

### Via Homebrew (recommended)

```bash
brew tap lokesh2021/claude-status
brew install claude-status
```

### Quick install (no Homebrew)

```bash
curl -fsSL https://raw.githubusercontent.com/lokesh2021/homebrew-claude-status/main/install.sh | bash
```

### From source

```bash
git clone https://github.com/lokesh2021/homebrew-claude-status
cd homebrew-claude-status
./install.sh
```

## Setup

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "claude-status"
  }
}
```

Open a new Claude Code session — the status line appears at the bottom automatically.

## Usage reports

```bash
claude-stats               # today + week + month + all-time summary
claude-stats today         # today only
claude-stats week          # last 7 days
claude-stats month         # this calendar month
claude-stats all           # all-time totals
claude-stats history       # last 20 sessions
claude-stats history 50    # last 50 sessions
claude-stats reset         # wipe all stored data
```

Example output:

```
  Claude Code Usage  · data: ~/.local/share/claude-status/data
  ────────────────────────────────────────────────────────
  Today  (2026-03-25)
    Sessions     3
    Cost         $0.0847
    Input        45,231 tokens
    Output       12,453 tokens
    Total        57,684 tokens

  This week  (last 7 days)
    Sessions     18
    Cost         $0.5234
    Input        234,123 tokens
    Output       67,234 tokens
    Total        301,357 tokens

  This month  (since 2026-03-01)
    Sessions     47
    Cost         $1.8910
    Input        789,234 tokens
    Output       234,567 tokens
    Total        1,023,801 tokens

  ────────────────────────────────────────────────────────
  All time
    Sessions     123
    Cost         $5.4500
    Input        2,345,678 tokens
    Output       789,012 tokens
    Total        3,134,690 tokens
```

## Game modes

Reskin the status line with a themed overlay for fun. Switch modes with:

```bash
claude-status game             # show current mode + available modes
claude-status game rpg         # switch to a mode
claude-status game none        # back to default
```

| Mode | Preview |
|---|---|
| `none` | `⎇ main  ·  Sonnet 4.6  ·  $0.04  ·  ctx [████░░░░░░] 40%  ·  2m30s` |
| `rpg` | `🧙 Lv.4  ·  HP [████████░░] 80%  ·  ⎇ main  ·  +5k XP  ·  💰$0.04` |
| `space` | `🚀 M#12  ·  fuel [████████░░] 80%  ·  ⎇ main  ·  5k ly  ·  $0.04` |
| `tamagotchi` | `🐱 lokesh2021  ·  😊  ·  fed [████░░░░░░] 40%  ·  2m30s  ·  $0.04` |
| `dungeon` | `⚔️  F.12  ·  depth [████░░░░░░] 40%  ·  ⎇ main  ·  $0.04` |
| `streaks` | `🔥 7d  ·  ⎇ main  ·  Sonnet 4.6  ·  $0.04  ·  ctx [████░░░░░░] 40%` |
| `invader` | `ctx [····@·····] 40%  ·  ⎇ main  ·  Sonnet 4.6  ·  $0.04` |

Each mode re-uses live session data — no extra tracking. Danger states activate at ≥90% context: HP/fuel bars turn red, dungeon shows `🐉 boss!`, tamagotchi becomes `😵`, invader fires `💥`. RPG level and mission/floor counts are derived from your all-time session history.

## Configuration

| Environment variable | Default | Description |
|---|---|---|
| `CLAUDE_STATUS_DATA_DIR` | `~/.local/share/claude-status` | Where to store session data |

## Data storage

Session data is stored as append-only JSONL files (one per day):

```
~/.local/share/claude-status/
├── config.json              # cached GitHub username + active game mode
├── game_cache.json          # daily cache of all-time totals for game modes
└── data/
    ├── 2026-03-25.jsonl
    ├── 2026-03-24.jsonl
    └── ...
```

Each line is a session snapshot. Sessions are deduplicated by `session_id` at read time (last write wins), so costs aren't double-counted.

## Requirements

- **jq** — `brew install jq`
- **git** (optional) — for branch display and GitHub username detection from remotes
- **gh** (optional) — for GitHub username detection (`brew install gh`)

GitHub username is resolved automatically via multiple fallbacks — no manual configuration needed:

| Priority | Source | Notes |
|---|---|---|
| 1 | `gh auth status` | Most accurate; respects multi-account setups |
| 2 | `~/.config/gh/hosts.yml` | Works even without the `gh` binary installed |
| 3 | `$GITHUB_USER` / `$GITHUB_ACTOR` | CI environments, devcontainers |
| 4 | `git config --global github.user` | Set manually with `git config --global github.user <name>` |
| 5 | `git remote get-url origin` | Parsed from the current repo's GitHub remote URL |

## License

MIT
