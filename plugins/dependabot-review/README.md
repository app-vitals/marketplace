# dependabot-review v0.2.1

AI-powered triage of Dependabot PRs across multiple repos. Stages patrol-style risk assessments for conversational review — you walk through them with the agent and decide which to post.

Extracted from [patrol](https://github.com/app-vitals/patrol) — the same triage logic, now available as a Claude Code skill.

## Workflow

1. **Cron runs `/triage-dependabot-prs`** — scans repos, triages new Dependabot PRs, stages comments to `state/dependabot-reviews/`
2. **Agent notifies you** — summary of what's staged
3. **You review conversationally** — "walk me through the staged dependabot reviews" — agent presents each one and posts when you say go

Nothing posts to GitHub until you confirm.

## Commands

### `/triage-dependabot-prs`

Scans all repos in `repos/` for open Dependabot PRs. Triages any new ones and stages the comments. Does not post.

```
/triage-dependabot-prs
```

Updates `state/dependabot-reviews.json` and writes staged comment files to `state/dependabot-reviews/`.

## Skills

### `triage-dependabot-pr`

Analyzes a single Dependabot PR and stages a patrol-style comment. Use for one-off triage or as a building block for the bulk command.

```
/triage-dependabot-pr 42
/triage-dependabot-pr 42 --repo app-vitals/vitals-os
```

Outputs the formatted comment inline and writes it to `state/dependabot-reviews/DEP_REVIEW_{repo}_{pr}.md`. Does not post to GitHub.

## State file

`state/dependabot-reviews.json` tracks all PRs:

```json
[
  {
    "pr": 42,
    "repo": "vitals-os",
    "org": "app-vitals",
    "title": "Bump axios from 1.6.0 to 1.7.0",
    "branch": "dependabot/npm_and_yarn/axios-1.7.0",
    "firstSeen": "2026-04-21T10:00:00Z",
    "lastTriagedAt": "2026-04-21T10:00:00Z",
    "recommendation": "merge",
    "stagedFile": "state/dependabot-reviews/DEP_REVIEW_app-vitals_vitals-os_42.md",
    "status": "staged",
    "postedAt": null,
    "mergedAt": null
  }
]
```

**Status flow:** `pending → staged → posted → merged`

## Risk assessment

| Recommendation | When |
|---|---|
| ✅ merge | Patch/minor bump, no breaking changes, CI passing |
| ⚠️ review | Major bump, breaking changes possible, security-relevant |
| 🛑 hold | Confirmed breaking change, deprecated package, code changes required |

**Flags:**
- 🔴 Breaking change — major version bump or body mentions breaking changes
- 🔒 Security relevant — CVE mentioned, or security-related package
- 🏭 Production impact — package is in `dependencies`, not `devDependencies`
