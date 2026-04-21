# Testing: dependabot-review

## Prerequisites

- `gh` CLI authenticated (`gh auth status`)
- At least one open Dependabot PR in a repo under `repos/` (or use `--repo` directly)
- `state/` directory exists in workspace root

## Test: triage-dependabot-pr skill (standalone)

1. Find a repo with an open Dependabot PR: `gh pr list --repo {owner}/{repo} --author "app/dependabot" --state open`
2. Run: `/triage-dependabot-pr <number> --repo {owner}/{repo}`

**Verify:**
- [ ] Fetches PR metadata and diff without errors
- [ ] Correctly classifies patch/minor/major bump
- [ ] Outputs the formatted comment inline
- [ ] Writes staged file to `state/dependabot-reviews/DEP_REVIEW_{repo_slug}_{pr}.md`
- [ ] Creates/updates entry in `state/dependabot-reviews.json` with `status: "staged"`
- [ ] Does NOT post a comment to the PR on GitHub
- [ ] Re-running updates the staged file (no duplicates)

## Test: triage-dependabot-prs command (no repos)

1. In a workspace with an empty `repos/` directory
2. Run: `/triage-dependabot-prs`

**Verify:**
- [ ] Reports "No pending Dependabot PRs. All up to date." and stops cleanly

## Test: triage-dependabot-prs command (multiple repos)

1. In a workspace with repos in `repos/`, at least one having open Dependabot PRs
2. Run: `/triage-dependabot-prs`

**Verify:**
- [ ] Detects owner/repo for each directory in `repos/`
- [ ] Finds open Dependabot PRs across all repos
- [ ] Adds new PRs as `pending` entries in state
- [ ] Triages each pending PR and marks as `staged`
- [ ] Writes a staged file per PR
- [ ] Outputs summary table with repo, PR, recommendation, status
- [ ] Does NOT post any comments to GitHub
- [ ] Re-running: skips already-staged PRs, detects newly merged ones

## Test: merged PR sync

1. With a `staged` entry in `state/dependabot-reviews.json` for a PR that has since merged
2. Run: `/triage-dependabot-prs`

**Verify:**
- [ ] Detects the PR is merged via `gh pr view --json state`
- [ ] Updates entry to `status: "merged"` with `mergedAt` timestamp
- [ ] Does not re-triage the merged PR

## Test: conversational post flow

1. With staged reviews in `state/dependabot-reviews.json`
2. Ask the agent: "walk me through the staged dependabot reviews"

**Verify:**
- [ ] Agent reads state file and presents each staged review
- [ ] Agent reads the staged comment file for each PR
- [ ] When confirmed, agent posts the comment to GitHub using `gh pr comment`
- [ ] Agent updates state entry to `status: "posted"` with `postedAt` timestamp

## Test: breaking change detection

1. Find a Dependabot PR for a major version bump (X.y.z → X+1.y.z)
2. Run: `/triage-dependabot-pr <number> --repo {owner}/{repo}`

**Verify:**
- [ ] Recommendation is `review` or `hold` (not `merge`)
- [ ] `🔴 Breaking change` flag appears in staged comment if appropriate
- [ ] Reasoning mentions the major version bump

## Test: security-relevant detection

1. Find a Dependabot PR where the body mentions a CVE
2. Run: `/triage-dependabot-pr <number> --repo {owner}/{repo}`

**Verify:**
- [ ] `🔒 Security relevant` flag appears in staged comment
- [ ] Recommendation is at least `review`
