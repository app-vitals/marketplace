---
name: triage-dependabot-prs
description: Triage all open Dependabot PRs in the current repo. Analyzes each one, posts patrol-style comments, and works to get them to merge-ready (enabling auto-merge on safe ones, explaining what's needed for others).
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

# Triage All Dependabot PRs

Work through every open Dependabot PR in the current repo and get them to merge-ready.

## 1. Detect repo

```bash
gh repo view --json nameWithOwner -q '.nameWithOwner'
```

Extract `owner` and `repo` from the output.

## 2. Fetch all open Dependabot PRs

```bash
gh pr list --author "app/dependabot" --state open --json number,title,url,headRefName,isDraft
```

If empty, report "No open Dependabot PRs found." and stop.

List the PRs found at the top of your response before diving in.

## 3. Triage each PR

For each PR, run the `triage-dependabot-pr` skill with the PR number as the argument.

The skill handles fetching PR details and diff, analyzing risk, replacing any existing patrol comment, and posting the triage comment. Collect the recommendation (`merge`, `review`, or `hold`) from each skill run for use in step 4.

## 4. Act on recommendations

After triaging all PRs, take action:

### For `merge` PRs:

Enable auto-merge so they merge as soon as CI passes:

```bash
gh pr merge <number> --auto --squash
```

If auto-merge is unavailable (branch protection not set up), note it and suggest merging manually.

### For `review` PRs:

Dig deeper — try to resolve the concern and move them to `merge`:

1. **Read the package changelog or release notes** if Dependabot included a link in the body.
2. **Search the codebase** for usage of the changed package:
   ```bash
   grep -r "require.*<package>" src/ --include="*.ts" --include="*.js" -l
   ```
3. **Check if the breaking API is actually used** — if the codebase doesn't use the changed API, the risk drops.
4. If you can confirm the update is safe → upgrade the comment to `merge`, post an updated comment, enable auto-merge.
5. If genuinely uncertain → leave as `review` and explain specifically what a human needs to check.

### For `hold` PRs:

1. Explain exactly why it's on hold.
2. If a code change is needed to resolve compatibility, describe what the fix would look like.
3. Don't auto-merge. Flag for human action.

## 5. Summary report

After processing all PRs, output a summary table:

```
## Dependabot Triage Summary

| PR | Package | Bump | Recommendation | Action |
|----|---------|------|---------------|--------|
| #42 | axios | 1.6.0 → 1.7.0 | ✅ merge | Auto-merge enabled |
| #41 | webpack | 4.x → 5.x | 🛑 hold | Breaking change — needs migration |
| #40 | jest | 29.6 → 29.7 | ✅ merge | Auto-merge enabled |

**Total**: X merge, Y review, Z hold
```

Then give a short paragraph on anything that needs human attention.

## Notes

- Process PRs serially — don't parallelize, as merging one PR can create conflicts in others.
- If a PR has merge conflicts, note it in the summary — it may need a rebase first (`gh pr comment <number> --body "@dependabot rebase"`).
- The goal is: zero PRs left in an ambiguous state. Every PR should either be auto-merging or have a clear explanation of what's blocking it.
- Use `gh` CLI for all GitHub interactions. Respect the current `GH_TOKEN` / `gh auth` context.
