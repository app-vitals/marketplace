# pr-review

Interactive PR review workflow for Claude Code with local drafts, CLAUDE.md compliance checking, and iterative refinement before posting to GitHub.

## Features

- **Local-first drafts**: Review saved to `PR_REVIEW_<number>.md` for iteration before posting
- **CLAUDE.md compliance**: Checks code against project guidelines
- **Confidence scoring**: Issues rated 0-100 to reduce false positives
- **Follow-up reviews**: Track if previous comments were addressed
- **Review queue + parallel batch**: Fetch PRs needing attention and process via cloud-agent

## Commands

### `/review-pr <pr-number-or-url>`

Full PR review with local draft workflow.

1. Checks out PR branch
2. Analyzes diff and reads CLAUDE.md
3. Scores issues by confidence
4. Saves draft to `PR_REVIEW_<number>.md`
5. Iterates with you before posting
6. Posts bundled review with inline comments

### `/review-pr-update <pr-number>`

Follow-up review after PR is updated.

- References your previous review
- Checks if comments were addressed (✅/⚠️/❌)
- Reviews new code added since last review
- Appends update section to original review file

### `/ca-review-prs [pr-numbers...] or [repo] [--limit N]`

Fetch PRs needing review and process them in parallel via cloud-agent.

**Without PR numbers** - fetches your review queue:
- Shows PRs where you're requested as reviewer
- Shows PRs you haven't reviewed yet
- Shows PRs updated since your review
- Queue all or select specific PRs for parallel review

**With PR numbers** - queues reviews directly:
- Runs reviews in parallel on cloud infrastructure
- Monitors progress in background
- Applies completed reviews locally for iteration

**Requires**: [cloud-agent CLI](https://github.com/app-vitals/cloud-agent)

## Prerequisites

- [GitHub CLI](https://cli.github.com/) (`gh`) - Required for all commands
- [cloud-agent CLI](https://github.com/app-vitals/cloud-agent) (`ca`) - Required for parallel batch reviews only

## Workflow

### Daily Review Session

```bash
# See what needs review and batch process
/ca-review-prs

# Or review specific PRs
/ca-review-prs 123 456 789

# Or review one at a time
/review-pr 123
```

### Follow-up on Updated PRs

```bash
# After PR author pushes changes
/review-pr-update 123
```

### Review Approval Phrases

- "Looks good, approved"
- "Looks good, approved with comments"
- "Looks good, I have a few suggestions"

## Files Created

| File | Purpose | When to Delete |
|------|---------|----------------|
| `PR_REVIEW_<n>.md` | Review draft and history | After PR merged |
| `pr_review_<n>.json` | GitHub API payload | After PR merged |

## Best Practices Encoded

- **Stay on PR branch** after review for follow-up questions
- **Inline comments** only on diff lines (GitHub limitation)
- **Keep review files** until PR is merged
- **Check CLAUDE.md** for project-specific patterns
- **Score issues** by confidence to reduce noise

## CLI Wrapper

The `scripts/review-pr` wrapper lets you start a PR review directly from terminal with pre-approved tools (no permission prompts for gh/git commands).

**Install once:**
```
/install-pr-review
```

This symlinks `review-pr` to `~/.local/bin/`. Then use from any repo:

```bash
review-pr 123
review-pr https://github.com/owner/repo/pull/123
```

**Uninstall:**
```
/uninstall-pr-review
```

This is useful when you review PRs across many different repos and don't want to configure per-project settings.

## Installation

Add to your Claude Code plugins:

```bash
claude plugins add app-vitals/marketplace --path plugins/pr-review
```

Or clone and link locally:

```bash
git clone https://github.com/app-vitals/marketplace
claude --plugin-dir marketplace/plugins/pr-review
```

## License

MIT
