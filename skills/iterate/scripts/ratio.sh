#!/usr/bin/env bash
# ratio.sh — actual Survive/Invest/Grow mix from git history, and the current deficit.
# usage: ratio.sh [--since "30 days ago"] [--author <pattern>] [--ratio 1:1:1]
# Classification order per commit:
#   1. NRT-Bucket: trailer (survive|invest|grow)
#   2. Conventional-commit type
#   3. unclassified (reported, not counted toward the ratio)
# Bash 3.2 compatible (stock macOS).
set -euo pipefail

since="30 days ago"; author=""; ratio="${NRT_RATIO:-1:1:1}"
while [[ $# -gt 0 ]]; do
  case $1 in
    --since)  since=$2;  shift 2 ;;
    --author) author=$2; shift 2 ;;
    --ratio)  ratio=$2;  shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

IFS=: read -r ts ti tg <<<"$ratio"
s=0; i=0; g=0; u=0

args=(log --no-merges --since="$since"
      --format='%s%x09%(trailers:key=NRT-Bucket,valueonly,separator=%x20)')
[[ -n $author ]] && args+=(--author="$author")

re='^([a-z]+)(\([^)]*\))?!?:'
while IFS=$'\t' read -r subject trailer; do
  [[ -z $subject ]] && continue
  b=$(printf '%s' "${trailer%% *}" | tr '[:upper:]' '[:lower:]')
  if [[ $b != survive && $b != invest && $b != grow ]]; then
    b=""
    lc=$(printf '%s' "$subject" | tr '[:upper:]' '[:lower:]')
    if [[ $lc == revert* ]]; then
      b=survive
    elif [[ $lc =~ $re ]]; then
      case ${BASH_REMATCH[1]} in
        fix|hotfix|security|sec)                             b=survive ;;
        refactor|perf|chore|ci|build|test|docs|style|deps)   b=invest  ;;
        feat|feature)                                        b=grow    ;;
      esac
    fi
  fi
  case $b in
    survive) s=$((s+1)) ;;
    invest)  i=$((i+1)) ;;
    grow)    g=$((g+1)) ;;
    *)       u=$((u+1)) ;;
  esac
done < <(git "${args[@]}")

awk -v s="$s" -v i="$i" -v g="$g" -v u="$u" -v ts="$ts" -v ti="$ti" -v tg="$tg" -v since="$since" '
BEGIN {
  n = s + i + g; t = ts + ti + tg
  printf "window: %s  classified: %d  unclassified: %d  target %s:%s:%s\n", since, n, u, ts, ti, tg
  split("survive invest grow", name, " ")
  a[1] = s; a[2] = i; a[3] = g
  w[1] = ts; w[2] = ti; w[3] = tg
  best = 1; bestd = -1e9
  for (k = 1; k <= 3; k++) {
    pct = n ? 100 * a[k] / n : 0
    d = n * w[k] / t - a[k]           # commits short of target
    printf "%-8s %3d  %5.1f%%  (target %5.1f%%)  deficit %+.1f\n", name[k], a[k], pct, 100 * w[k] / t, d
    if (d > bestd + 1e-9) { bestd = d; best = k }   # ties resolve survive > invest > grow
  }
  if (n == 0) best = 1
  printf "NRT_DEFICIT=%s\n", name[best]
}'
