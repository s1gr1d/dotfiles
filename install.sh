#!/usr/bin/env bash
#
# Symlink this dotfiles repo into the locations each tool expects.
# Idempotent: safe to re-run. Anything already at a target is backed up to
# <target>.bak[-n] before the symlink is created.
#
# Usage: ./install.sh [--dry-run]
#
# Links created (source is relative to the repo, target to $HOME):
#   ~/.zshrc            -> shell/zshrc         (sources shell/zsh/*.zsh)
#   ~/.prompts          -> agents/prompts      (the `pp` shell function reads these)
#   ~/.claude/skills    -> agents/skills       (Claude Code auto-loads these)
#   ~/.claude/CLAUDE.md -> agents/AGENTS.md    (Claude Code global instructions)
#   ~/.codex/AGENTS.md  -> agents/AGENTS.md    (Codex global instructions)
#
# Tool skill/instruction paths drift between releases — if a link stops being
# picked up, check that tool's current docs for its expected path.

set -euo pipefail

# Absolute path of this repo, so the script works from any clone location.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Edit this table to add or remove links. Format: "<repo-relative src>|<$HOME-relative dst>".
LINKS=(
  "shell/zshrc|.zshrc"
  "agents/prompts|.prompts"
  "agents/skills|.claude/skills"
  "agents/AGENTS.md|.claude/CLAUDE.md"
  "agents/AGENTS.md|.codex/AGENTS.md"
)

DRY_RUN=0
case "${1:-}" in
  -n|--dry-run) DRY_RUN=1 ;;
  -h|--help)    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "")           ;;
  *)            echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
esac

# Run a mutating command, or just describe it under --dry-run.
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "       would: $*"
  else
    "$@"
  fi
}

# Echo the first free "<dst>.bak" / "<dst>.bak-N" name.
backup_path() {
  local dst="$1" bak="$1.bak" n=1
  while [ -e "$bak" ] || [ -L "$bak" ]; do
    bak="$dst.bak-$n"; n=$((n + 1))
  done
  printf '%s' "$bak"
}

link() {
  local src="$1" dst="$2"

  if [ ! -e "$src" ]; then
    echo "skip:   missing source $src"
    return
  fi

  # Already the correct link — nothing to do.
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok:     $dst"
    return
  fi

  run mkdir -p "$(dirname "$dst")"

  # Move anything currently there (real file/dir or a stale symlink) aside.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local bak; bak="$(backup_path "$dst")"
    echo "backup: $dst -> $bak"
    run mv "$dst" "$bak"
  fi

  echo "link:   $dst -> $src"
  run ln -s "$src" "$dst"
}

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] previewing — no changes will be made"
fi

for pair in "${LINKS[@]}"; do
  link "$REPO/${pair%%|*}" "$HOME/${pair##*|}"
done

echo "done."
