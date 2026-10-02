#!/usr/bin/env bash
# memory.sh — locate (and optionally create) the NRT memory file.
# usage: memory.sh [--commit] [--init]
#   default   <main worktree>/.nrt/memory.md, shared by linked worktrees and
#             hidden from git through info/exclude (no tracked file changes)
#   --commit  <this worktree>/.nrt/memory.md, tracked like any other file
#   --init    create the file if missing and set the ignore rule for the mode
# Prints the path. Without --init nothing is written.
# Bash 3.2 compatible (stock macOS).
set -euo pipefail

commit=0; init=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --commit) commit=1; shift ;;
    --init)   init=1;   shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

root=""
if [[ $commit -eq 0 ]]; then
  # first entry is the main worktree; a bare repo has none, so fall through
  root=$(git worktree list --porcelain |
    awk 'NR==1 { sub(/^worktree /, ""); p = $0 } NR==2 && $0 == "bare" { p = "" } END { print p }')
fi
[[ -z $root ]] && root=$(git rev-parse --show-toplevel)
file="$root/.nrt/memory.md"

if [[ $init -eq 1 ]]; then
  exclude=$(git rev-parse --git-path info/exclude)
  rule='/.nrt/'
  if [[ $commit -eq 1 ]]; then
    if [[ -f $exclude ]] && grep -qxF "$rule" "$exclude"; then
      grep -vxF "$rule" "$exclude" > "$exclude.tmp" || true
      mv "$exclude.tmp" "$exclude"
    fi
  elif ! grep -qxF "$rule" "$exclude" 2>/dev/null; then
    mkdir -p "$(dirname "$exclude")"
    # keep the rule on its own line if the file lacks a trailing newline
    [[ -s $exclude && -n $(tail -c1 "$exclude") ]] && echo >> "$exclude"
    printf '%s\n' "$rule" >> "$exclude"
  fi

  if [[ ! -f $file ]]; then
    mkdir -p "$(dirname "$file")"
    cat > "$file" <<'EOF'
# Next Right Thing memory

Short-term notes for /next-right-thing:iterate. Not a changelog, braglog or
statuslog: only what the next run would otherwise re-derive or miss.
Entries expire 30 days after their date unless re-confirmed.

## Survive

### Findings

### Watch

## Invest

### Findings

### Watch

## Grow

### Findings

### Watch
EOF
  fi
fi

printf '%s\n' "$file"
