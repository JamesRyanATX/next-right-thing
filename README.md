# Next Right Thing

A Claude Code plugin that picks and does the next piece of work in a repo, using a portfolio rule instead of whatever's loudest.

## Survive / Invest / Grow

| Bucket  | Metaphor                | Covers |
|---------|-------------------------|--------|
| survive | keep the lights on      | bugs, outages, failing CI, security, broken deps |
| invest  | make the lights cheaper | toil removal, refactors, perf, CI speed, automation, docs |
| grow    | install new lights      | features, new capabilities, integrations |

In a balanced setting the ratio is **1:1:1**. `/nrt` measures the recent mix from git history and works the bucket that's furthest behind.

## Install

```
/plugin marketplace add JamesRyanATX/next-right-thing
/plugin install next-right-thing@jamesryanatx
```

## Use

```
/next-right-thing:nrt            # pick the bucket from the ratio deficit
/next-right-thing:nrt survive    # force a bucket
/next-right-thing:nrt invest
/next-right-thing:nrt grow
/next-right-thing:nrt --dry-run  # report the pick, change nothing
```

## How it decides

1. **Lights-out override** — red default-branch CI, open P0/security/incident issues, or a broken build forces `survive`, whatever the ratio.
2. **Ratio deficit** — `scripts/ratio.sh` classifies the last 30 days of commits by `NRT-Bucket:` trailer, then conventional-commit type, and picks the bucket furthest below target.
3. **Issues first** — open issues in that bucket, classified by label or content.
4. **Discovery** — if the bucket has no issues, look for real work in it (audits and failing tests for survive; slow CI, manual steps and untested hot files for invest; three proposed ideas for grow, which you pick from).
5. **One unit of work** — a branch `nrt/<bucket>/<slug>`, a commit with an `NRT-Bucket:` trailer, and a PR. Never merges.

## Configure

Target ratio, in priority order:

- `NRT_RATIO=2:1:1` environment variable
- `.nrt.yml` in the repo:

  ```yaml
  ratio: 2:1:1
  file_issues: false   # don't open issues for discovered work
  ```

- default `1:1:1`

Check the current mix yourself:

```
skills/nrt/scripts/ratio.sh --since "30 days ago" [--author <pattern>] [--ratio 1:1:1]
```

## Requirements

`git`, `bash`, `awk`. `gh` or `glab` for issue tracking (optional; without one, `/nrt` runs discovery only and skips PRs).

## License

MIT
