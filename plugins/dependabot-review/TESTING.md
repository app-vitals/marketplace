# Testing: dependabot-review

## Prerequisites

- `gh` CLI authenticated (`gh auth status`)
- At least one open Dependabot PR in the current repo (or use a test repo)

## Test: triage-dependabot-pr skill

1. Find a repo with an open Dependabot PR: `gh pr list --author "app/dependabot" --state open`
2. Run: `/triage-dependabot-pr <number>`

**Verify:**
- [ ] Fetches PR metadata and diff without errors
- [ ] Correctly classifies patch/minor/major bump
- [ ] Posts a patrol-style comment with `<!-- patrol -->` marker
- [ ] Comment includes icon (✅/⚠️/🛑), summary, and reasoning
- [ ] Re-running replaces the old comment (no duplicate comments)

## Test: triage-dependabot-prs command (no PRs)

1. In a repo with no open Dependabot PRs
2. Run: `/triage-dependabot-prs`

**Verify:**
- [ ] Reports "No open Dependabot PRs found" and stops cleanly

## Test: triage-dependabot-prs command (multiple PRs)

1. In a repo with 2+ open Dependabot PRs
2. Run: `/triage-dependabot-prs`

**Verify:**
- [ ] Lists all PRs at the top before processing
- [ ] Posts a comment on each PR
- [ ] Enables auto-merge on `merge`-rated PRs (or notes if unavailable)
- [ ] For `review` PRs: searches codebase for package usage
- [ ] For `hold` PRs: explains blocking reason
- [ ] Outputs summary table at the end with correct counts
- [ ] No duplicate comments on any PR

## Test: breaking change detection

1. Find or create a Dependabot PR for a major version bump (X.y.z → X+1.y.z)
2. Run: `/triage-dependabot-pr <number>`

**Verify:**
- [ ] Recommendation is `review` or `hold` (not `merge`)
- [ ] `breakingChange` flag appears in comment if appropriate
- [ ] Reasoning mentions the major version bump

## Test: security-relevant detection

1. Find a Dependabot PR where the body mentions a CVE
2. Run: `/triage-dependabot-pr <number>`

**Verify:**
- [ ] `securityRelevant` flag appears in comment
- [ ] Recommendation is at least `review`
