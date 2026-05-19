#!/usr/bin/env bash
# Install tracked Claude Code config from this repo into ~/.claude/.
# Per-mapping: copy if the destination doesn't exist; skip with a notice if it does.
# Never overwrites; missing source files are still fatal.

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

# Pre-flight: every source must exist.
missing=0
for entry in "${MAPPINGS[@]}"; do
  src="${SRC_DIR}/${entry%%::*}"
  if [[ ! -e "$src" ]]; then
    echo "ERROR: source missing: $src" >&2
    missing=1
  fi
done
if [[ "$missing" -ne 0 ]]; then
  echo >&2
  echo "Aborting — fix the missing sources and re-run." >&2
  exit 1
fi

mkdir -p "${DEST_DIR}/skills"

# Mode fixups to apply only when WE created the destination this run.
# Keyed by destination name (relative to DEST_DIR).
declare -A MODE_FIXUPS=(
  ["statusline-command.sh"]="+x"
  ["settings.json"]="600"
)

copied=0
skipped=0
for entry in "${MAPPINGS[@]}"; do
  src="${SRC_DIR}/${entry%%::*}"
  dst_rel="${entry##*::}"
  dst="${DEST_DIR}/${dst_rel}"
  if [[ -e "$dst" || -L "$dst" ]]; then
    echo "skip: $dst already exists"
    skipped=$((skipped + 1))
    continue
  fi
  echo "copy: $src -> $dst"
  if [[ -d "$src" ]]; then
    cp -r "$src" "$dst"
  else
    cp "$src" "$dst"
  fi
  if [[ -n "${MODE_FIXUPS[$dst_rel]+set}" ]]; then
    chmod "${MODE_FIXUPS[$dst_rel]}" "$dst"
  fi
  copied=$((copied + 1))
done

echo
echo "Done. copied=${copied} skipped=${skipped}"
if [[ "$skipped" -gt 0 ]]; then
  echo "To re-install a skipped item, remove or back up its destination and re-run."
fi
