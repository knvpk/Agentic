#!/usr/bin/env bash
# PreToolUse hook: block edits on a ticket branch that has no linked OpenSpec change.
# Reads the tool-call JSON on stdin. Exit 2 blocks the call (message goes to stderr).

input=$(cat)
path=$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"\(.*\)"/\1/')

case "$path" in
  */openspec/changes/*|openspec/changes/*) exit 0 ;;
esac

branch=$(git branch --show-current 2>/dev/null)
[ -z "$branch" ] && exit 0

ticket=$(printf '%s' "$branch" | grep -oiE '[A-Z]+-[0-9]+' | head -1)
if [ -z "$ticket" ]; then
  ticket=$(printf '%s' "$branch" | grep -oE '(^|/)[0-9]+' | head -1 | tr -d '/')
fi
[ -z "$ticket" ] && exit 0
num=${ticket##*-}

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
for f in "$root"/openspec/changes/*/.openspec.yaml; do
  [ -f "$f" ] || continue
  case "$f" in */archive/*) continue ;; esac
  if grep -qE "^[[:space:]]+id:[[:space:]]*['\"]?($ticket|$num)['\"]?[[:space:]]*$" "$f"; then
    exit 0
  fi
done

echo "Blocked: branch '$branch' references ticket $ticket but no active OpenSpec change links to it. Run /project-management start $ticket (or /opsx:explore, /opsx:ff) to create the change first." >&2
exit 2
