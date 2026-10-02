# Next Right Thing

A Claude Code plugin that picks and does the next piece of work in a repo, using a portfolio rule instead of whatever's loudest.

## Survive / Invest / Grow

| Bucket  | Metaphor                | Covers |
|---------|-------------------------|--------|
| survive | keep the lights on      | bugs, outages, failing CI, security, broken deps |
| invest  | make the lights cheaper | toil removal, refactors, perf, CI speed, automation, docs |
| grow    | install new lights      | features, new capabilities, integrations |

In a balanced setting the ratio is **1:1:1**. `/next-right-thing:iterate` measures the recent mix from git history and works the bucket that's furthest behind.

## Install

```
/plugin marketplace add JamesRyanATX/next-right-thing
/plugin install next-right-thing@jamesryanatx
```

## Use

```
/next-right-thing:iterate            # pick the bucket from the ratio deficit
/next-right-thing:iterate survive    # force a bucket
/next-right-thing:iterate invest
/next-right-thing:iterate grow
/next-right-thing:iterate --dry-run  # report the pick, change nothing
```

## How it decides

1. **Lights-out override** — red default-branch CI, open P0/security/incident issues, or a broken build forces `survive`, whatever the ratio.
2. **Ratio deficit** — `scripts/ratio.sh` classifies the last 30 days of commits by `NRT-Bucket:` trailer, then conventional-commit type, and picks the bucket furthest below target.
3. **Issues first** — open issues in that bucket, classified by label or content.
4. **Discovery** — if the bucket has no issues, look for real work in it (audits and failing tests for survive; slow CI, manual steps and untested hot files for invest; three proposed ideas for grow, which you pick from).
5. **One unit of work** — a branch `nrt/<bucket>/<slug>`, a commit with an `NRT-Bucket:` trailer, and a PR. Never merges.

## Memory

Runs keep a short-term memory in `.nrt/memory.md`, with a section for each bucket. It is a remember-me log, not a changelog or status log: it holds only what the next run would otherwise re-derive or miss.

- **Findings** — things that cost something to learn: a non-obvious root cause, a verified false positive, a dead end, a grow idea you rejected and why.
- **Watch** — parts of the codebase to check whenever that bucket is worked.

Entries are dated and expire after 30 days unless a later run re-confirms them, and each bucket holds about 10. Edit the file by hand whenever you like.

By default the file is local: it is hidden from git through `.git/info/exclude`, so your `.gitignore` is untouched and the next run sees new entries straight away. Set `memory: commit` in `.nrt.yml` to track it in the repo instead. Committed memory is shared and reviewable, but new entries reach later runs only once the PR that carries them merges, and PRs open at the same time can conflict on the file.

## Configure

Target ratio, in priority order:

- `NRT_RATIO=2:1:1` environment variable
- `.nrt.yml` in the repo:

  ```yaml
  ratio: 2:1:1
  file_issues: false   # don't open issues for discovered work
  memory: commit       # track .nrt/memory.md in the repo (default: local, git-ignored)
  ```

- default `1:1:1`

Check the current mix yourself:

```
skills/iterate/scripts/ratio.sh --since "30 days ago" [--author <pattern>] [--ratio 1:1:1]
```

## Origin

Most prioritization schemes rank individual tasks. Survive/Invest/Grow sets an allocation across kinds of work instead, the way a portfolio does, and ranks only inside each kind.

The idea came from reading Maslow. His hierarchy of needs is usually drawn as a pyramid and read as a ladder: finish one level, unlock the next. Maslow never drew the pyramid, and his 1943 paper, "A Theory of Human Motivation", says something different. Needs are met partially and all at once, and he gives illustrative figures for an average person: about 85% satisfied on physiological needs, 70% on safety, 50% on love, 40% on esteem and 10% on self-actualization. That is a ratio, not a sequence.

The three buckets apply that to a codebase. A repo that spends everything on survival is firefighting and calling it a plan; one that only chases growth lets the basics rot. Invest connects the two: making the lights cheaper lowers the cost of surviving, and the freed capacity pays for growth.

## Requirements

`git`, `bash`, `awk`. `gh` or `glab` for issue tracking (optional; without one, `/next-right-thing:iterate` runs discovery only and skips PRs).

## License

MIT
