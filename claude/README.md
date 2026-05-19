# Claude Code config

Tracked copies of my user-global Claude Code configuration. The live files live in `~/.claude/`; this directory is the canonical source committed to git.

## What's here

| Tracked file / dir              | Lives at                                  |
| ------------------------------- | ----------------------------------------- |
| `CLAUDE_user-level.md`          | `~/.claude/CLAUDE.md`                     |
| `settings_user-level.json`      | `~/.claude/settings.json`                 |
| `statusline-command.sh`         | `~/.claude/statusline-command.sh`         |
| `skills/agent-team/`            | `~/.claude/skills/agent-team/`            |

`settings.json` references `statusline-command.sh` by absolute path (`/home/kai/.claude/statusline-command.sh`), so the script must land there for the statusline to work.

## What's intentionally NOT tracked

- `teams/` — machine-specific tmux team configs.
- `projects/`, `sessions/`, `history.jsonl`, `todos/`, `tasks/`, `file-history/`, `shell-snapshots/`, `session-env/`, `jobs/`, `paste-cache/`, `telemetry/`, `usage-data/`, `statsig/`, `*-cache.json`, `backups/`, `cache/`, `downloads/`, `daemon*`, `ide/`, `plans/`, `debug/` — machine state, not config.
- `.credentials.json` — secret, never commit.
- `plugins/` — installed-plugin state; the enabled list is in `settings.json`, which is the reproducible bit.

## Restoring onto a fresh machine

From the repo root:

```sh
./claude/install.sh
```

The script copies each tracked file to its `~/.claude/` destination and **fails loudly if anything already exists there** — it never overwrites. If you want to re-sync after editing this repo, remove the destination file first (or back it up), then re-run.
