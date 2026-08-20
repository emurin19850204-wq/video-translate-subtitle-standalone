#!/usr/bin/env bash
# Install the skill into both Claude Code and Codex project skill locations.
# Usage: bash setup.sh [TARGET_ROOT] [--force]
set -euo pipefail

TARGET_ROOT=${1:-"$(pwd)"}
FORCE=0
if [[ "${2:-}" == "--force" ]]; then FORCE=1; fi
SOURCE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILL_NAME=video-translate-subtitle

if [[ ! -d "$SOURCE_ROOT" ]]; then
  echo "error: skill source directory not found: $SOURCE_ROOT" >&2
  exit 2
fi

copy_skill() {
  local destination=$1
  if [[ -e "$destination" && $FORCE -ne 1 ]]; then
    echo "Skipped existing installation: $destination"
    echo "Use --force to replace it."
    return
  fi
  rm -rf "$destination"
  mkdir -p "$destination"
  cp "$SOURCE_ROOT/SKILL.md" "$destination/"
  for folder in scripts references agents; do
    if [[ -d "$SOURCE_ROOT/$folder" ]]; then
      cp -R "$SOURCE_ROOT/$folder" "$destination/"
    fi
  done
  find "$destination" -type d -name __pycache__ -prune -exec rm -rf {} +
  find "$destination" -type f -name '*.pyc' -delete
  echo "Installed: $destination"
}

copy_skill "$TARGET_ROOT/.claude/skills/$SKILL_NAME"
copy_skill "$TARGET_ROOT/.agents/skills/$SKILL_NAME"

echo
printf 'Claude Code: invoke /%s or ask for English-to-Japanese video subtitles.\n' "$SKILL_NAME"
printf 'Codex: invoke $%s or ask for English-to-Japanese video subtitles.\n' "$SKILL_NAME"
echo 'Required runtime tools: ffmpeg, ffprobe, python3, and (optionally) fc-match.'
