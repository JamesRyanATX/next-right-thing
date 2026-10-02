---
name: nrt
description: Do the next right piece of work in this repo, chosen to keep a Survive/Invest/Grow balance (default 1:1:1). Use when the user types /nrt or asks for the next right thing to work on, optionally with survive, invest or grow to force a bucket.
argument-hint: "[survive|invest|grow] [--dry-run]"
---

# /nrt — Next Right Thing

Pick **one** unit of work and do it. The pick comes from a portfolio rule, not from whatever is loudest.

| Bucket  | Metaphor             | Covers |
|---------|----------------------|--------|
| survive | keep the lights on   | bugs, outages, failing CI, security, broken deps, data loss risk |
| invest  | make the lights cheaper | toil removal, refactors, perf, test/CI speed, automation, docs that cut support load, dep hygiene |
| grow    | install new lights   | features, new capabilities, new integrations, UX the user can see |

Arguments: `$ARGUMENTS`

- empty → choose the bucket (step 2)
- `survive` | `invest` | `grow` → use that bucket, skip step 2
- `--dry-run` → stop after step 5 (report the pick, change nothing)

## 1. Orient

- Confirm a git repo; note default branch and `git status`. If the tree is dirty, stop and ask — don't stack work on uncommitted changes.
- Detect the tracker: `gh` (GitHub), `glab` (GitLab), else none. Check auth once; if it fails, continue with tracker = none and say so.
- Read target ratio: `NRT_RATIO` env, else `.nrt.yml` key `ratio:` (e.g. `2:1:1`), else `1:1:1`.

## 2. Choose the bucket

### 2a. Lights-out override (always runs, even with a forced bucket)

Survive wins regardless of ratio if any of these are true:

- default-branch CI is red (`gh run list -b <default> -L 5`)
- open issues labelled `P0`, `sev1`, `incident`, `security`, `critical`, `outage`, or a security advisory is open
- the build or test suite is broken locally (only check if cheap — a known `make test`/`npm test` under ~2 min)

If the user forced `invest`/`grow` and the override trips, say so in one line and ask whether to proceed anyway. Otherwise go to survive.

### 2b. Ratio deficit

Run `bash "${CLAUDE_PLUGIN_ROOT}/skills/nrt/scripts/ratio.sh" --since "30 days ago"` (add `--author` only if the user asked for personal balance). It classifies commits by `NRT-Bucket:` trailer, then conventional-commit type, and prints `NRT_DEFICIT=<bucket>`. Use that bucket.

If fewer than 5 commits are classified, the signal is noise: treat as 1:1:1 starting fresh and pick survive → invest → grow by whichever has the strongest candidate in step 3.

## 3. Gather candidates — issues first

Pull open issues (cap ~100): `gh issue list --state open --limit 100 --json number,title,labels,createdAt,updatedAt,comments,assignees`.

Skip issues assigned to someone else, labelled `blocked`/`wontfix`/`needs-design`/`question`, or with an open linked PR.

Classify each into a bucket:

1. Label match — `bug`, `security`, `incident`, `regression`, `crash` → survive; `tech-debt`, `refactor`, `perf`, `chore`, `ci`, `dx`, `toil`, `docs`, `dependencies` → invest; `enhancement`, `feature`, `feature-request` → grow.
2. No useful label → read title/body and judge with the table above. Ask: *if we ignore this, do the lights go off (survive), do they keep costing us (invest), or do we just not get the new light (grow)?*

Keep only candidates in the chosen bucket.

## 4. Discovery — when the bucket has no issues

Don't drift to another bucket just because the tracker is empty; look for real work in the chosen one.

**Survive discovery** — run what's cheap and present in the repo:
- dependency vulnerabilities (`npm audit`, `pip-audit`, `govulncheck`, `cargo audit`, `trivy fs`)
- failing/flaky tests, lint errors, type errors
- deprecated APIs or EOL runtimes/base images; expiring certs or pinned versions near EOL
- `TODO|FIXME|XXX|HACK` comments that describe incorrect behaviour

**Invest discovery** — find what costs time repeatedly:
- slowest tests and CI jobs; missing caching
- manual steps in README/runbooks that could be a script or make target
- duplicated code, dead code, hot files with no tests (`git log --format= --name-only | sort | uniq -c | sort -rn | head`)
- stale or major-version-behind dependencies
- docs gaps that generate repeat questions

**Grow discovery** — this is ideation, so involve the user:
- read README, roadmap/ROADMAP, CHANGELOG, open discussions, and `TODO` comments that describe missing capability
- compare stated purpose to what exists; look at gaps an adjacent user would hit first
- propose **3** concrete ideas, each one line + estimated size; ask the user to pick (AskUserQuestion when available). Grow is taste — never pick silently.

If survive discovery finds nothing, the lights are on: say so and fall through to the next-largest deficit bucket. For invest/grow, fall through only if discovery genuinely comes up empty.

## 5. Rank and pick one

Within the bucket, score roughly:

- **impact** — users or systems affected, blast radius, frequency
- **cost of delay** — gets worse with time? (security, data growth, deprecation dates)
- **size** — prefer what fits one session (target: reviewable PR, ≲ 400 lines changed)
- **freshness** — recent activity/comments beat stale, unless stale means "ignored but important"
- **unblocks** — work that unblocks other open issues ranks up

Too big to fit? Pick its smallest shippable slice and say what the slice is.

Report before starting, tersely:

```
NRT  bucket=invest (deficit +3.2; 30d: S 12 / I 5 / G 9; target 1:1:1)
pick #142 Cache Go modules in CI — CI median 11m, ~4m is module download
next #131 flaky TestReconcile, #118 dedupe retry helpers
```

`--dry-run` stops here. Otherwise proceed — no confirmation needed for an existing issue. For discovered (non-issue) work, open an issue first only if a tracker exists and the user hasn't opted out (`.nrt.yml` `file_issues: false`), so the work is traceable.

## 6. Do the work

- Branch: `nrt/<bucket>/<issue#-or-slug>` off the default branch.
- Stay in scope. Anything else you notice goes into a new issue (with its bucket label), not this branch.
- Tests: add or update tests for survive and invest work; grow work gets at least a happy-path test.
- Commit with conventional-commit type matching the bucket and a trailer, so the ratio stays measurable:

  ```
  ci: cache Go modules in CI

  NRT-Bucket: invest
  Refs: #142
  ```

- Open a PR if a tracker exists; reference the issue and state the bucket in the description. Don't merge.

## 7. Close out

One short block: what changed, PR link, ratio after this commit, and the runner-up for the next `/nrt`. No step recap.

## Rules

- One unit of work per invocation.
- Never fake balance: if survive work exists past the override, it gets done even if survive is over ratio.
- Never relabel work to fit a bucket. If it doesn't fit the chosen bucket, it's not a candidate.
- Destructive or hard-to-undo actions (force-push, deleting branches, closing others' issues, prod changes) need explicit user confirmation.
