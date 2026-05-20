# Claude Code config

Tracked copies of my user-global Claude Code configuration. The live files live in `~/.claude/`; this directory is the canonical source committed to git.

## What's here

| Tracked file / dir              | Lives at                                  |
| ------------------------------- | ----------------------------------------- |
| `CLAUDE_user-level.md`          | `~/.claude/CLAUDE.md`                     |
| `git-workflow.md`               | `~/.claude/git-workflow.md`               |
| `settings_user-level.json`      | `~/.claude/settings.json`                 |
| `statusline-command.sh`         | `~/.claude/statusline-command.sh`         |
| `skills/agent-team/`            | `~/.claude/skills/agent-team/`            |

`settings.json` references `statusline-command.sh` via `~/.claude/statusline-command.sh`, so the script must land in `~/.claude/` for the statusline to render. The tilde is expanded by Claude Code, so the config is portable across machines and usernames (Linux + macOS).

## What's intentionally NOT tracked

- `teams/` — machine-specific tmux team configs.
- `projects/`, `sessions/`, `history.jsonl`, `todos/`, `tasks/`, `file-history/`, `shell-snapshots/`, `session-env/`, `jobs/`, `paste-cache/`, `telemetry/`, `usage-data/`, `statsig/`, `*-cache.json`, `backups/`, `cache/`, `downloads/`, `daemon*`, `ide/`, `plans/`, `debug/` — machine state, not config.
- `.credentials.json` — secret, never commit.
- `plugins/` — installed-plugin state; the enabled list is in `settings.json`, which is the reproducible bit.

## Restoring onto a fresh machine

### Requirements

- `bash` (already present on Linux + macOS)
- `jq` — needed by `statusline-command.sh` to parse Claude Code's JSON input. Without it the statusline renders empty/zero fields.
  - macOS: `brew install jq`
  - Debian/Ubuntu: `sudo apt install jq`
  - Fedora: `sudo dnf install jq`
- `git` (Claude Code installs it as a dep, but worth confirming)

### Install

From the repo root:

```sh
./claude/install.sh
```

The script is per-mapping idempotent: it copies each tracked file to its `~/.claude/` destination, and **skips any destination that already exists** — it never overwrites. Re-running after this repo gains a new tracked file installs just the new one. To re-sync an existing destination, remove or back it up first, then re-run.

After it finishes the script prints warnings if (a) `~/.claude/settings.json` was skipped (so the statusline / permission allowlist from this repo isn't active), or (b) `jq` isn't on PATH.

### Merging settings.json

If `~/.claude/settings.json` already exists, install.sh skips it — your live file is untouched. To pick up the tracked statusLine pointer and permission allowlist, diff and merge by hand:

```sh
diff ~/.claude/settings.json claude/settings_user-level.json
```
