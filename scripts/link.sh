#!/usr/bin/env bash
# Symlink global/CLAUDE.md into ~/.claude. Idempotent; never overwrites.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="${root}/global/CLAUDE.md"
dst="${HOME}/.claude/CLAUDE.md"
mkdir -p "$(dirname "$dst")"

if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
  echo "ok      $dst"
elif [[ -e "$dst" || -L "$dst" ]]; then
  echo "error: $dst exists and is not a link to $src; back it up and remove it first" >&2
  exit 1
else
  ln -s "$src" "$dst"
  echo "linked  $dst -> $src"
fi
