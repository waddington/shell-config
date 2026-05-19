#!/usr/bin/env bash
# Install tracked Claude Code config from this repo into ~/.claude/.
# Fails if any destination already exists — never overwrites.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${HOME}/.claude"

# Mapping: "<src relative to SRC_DIR>::<dest relative to DEST_DIR>"
MAPPINGS=(
  "CLAUDE_user-level.md::CLAUDE.md"
  "git-workflow.md::git-workflow.md"
  "settings_user-level.json::settings.json"
  "statusline-command.sh::statusline-command.sh"
  "skills/agent-team::skills/agent-team"
)

# Pre-flight: refuse if any destination already exists.
clash=0
for entry in "${MAPPINGS[@]}"; do
  src="${SRC_DIR}/${entry%%::*}"
  dst="${DEST_DIR}/${entry##*::}"
  if [[ ! -e "$src" ]]; then
    echo "ERROR: source missing: $src" >&2
    clash=1
    continue
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    echo "ERROR: destination already exists: $dst" >&2
    clash=1
  fi
done
if [[ "$clash" -ne 0 ]]; then
  echo >&2
  echo "Aborting — no files were copied. Remove or back up the clashing destinations and re-run." >&2
  exit 1
fi

mkdir -p "${DEST_DIR}/skills"

for entry in "${MAPPINGS[@]}"; do
  src="${SRC_DIR}/${entry%%::*}"
  dst="${DEST_DIR}/${entry##*::}"
  echo "copy: $src -> $dst"
  if [[ -d "$src" ]]; then
    cp -r "$src" "$dst"
  else
    cp "$src" "$dst"
  fi
done

# Preserve executable bit on the statusline script.
chmod +x "${DEST_DIR}/statusline-command.sh"

# settings.json is mode 0600 in the live tree; mirror that for the secret-adjacent allowlist.
chmod 600 "${DEST_DIR}/settings.json"

echo
echo "Done."
