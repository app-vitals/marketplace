# dependabot-review

AI-powered triage of Dependabot PRs. Analyzes dependency updates and posts patrol-style risk assessments. Bulk command works through all open Dependabot PRs and gets them to merge-ready.

Extracted from [patrol](https://github.com/app-vitals/patrol) — the same triage logic, now available as a Claude Code skill you can run on demand.

## Commands

### `/triage-dependabot-prs`

Processes every open Dependabot PR in the current repo:
1. Fetches all open Dependabot PRs
2. Triages each one (patch/minor/major bump, security relevance, production impact)
3. Posts a patrol-style comment on each PR
4. Enables auto-merge on safe ones
5. Digs deeper on review-flagged PRs to see if they can be cleared
6. Outputs a summary table of what happened and what needs human attention

```
/triage-dependabot-prs
```

## Skills

### `triage-dependabot-pr`

Analyzes a single Dependabot PR and posts a risk assessment comment. Use this for one-off triage or as a building block.

```
/triage-dependabot-pr 42
```

Posts a comment like:

```
### ✅ Patrol: Safe to merge

**Bumps axios from 1.6.0 to 1.7.0 — minor release, no breaking changes.**

🏭 Production impact

Axios 1.7 is a minor release that fixes response header handling. No deprecated APIs are removed. The project uses axios for HTTP requests in production paths, but the change is backward-compatible.

🏔️ patrol · claude-sonnet-4-6
```

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

## Relation to patrol

[Patrol](https://github.com/app-vitals/patrol) runs automatically as a GitHub Action on every Dependabot PR. This plugin lets you run the same triage manually from Claude Code — useful for:
- Repos that don't have patrol installed yet
- Bulk processing a backlog of existing PRs
- Reviewing patrol's work and double-checking its assessments
