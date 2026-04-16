# Reviews Schema -- Shipwright Review Tracking

Review state is tracked in `state/reviews.json`. Each entry represents an agent's
relationship with a PR -- whether it's been reviewed, posted, merged, or cleaned up.

## Schema

```json
{
  "pr": 123,
  "repo": "ok-wow",
  "org": "ok-wow",
  "title": "Add billing webhook handler",
  "author": "agent-okwow",
  "branch": "feat/ts-1.1-billing-webhook",
  "taskId": "TS-1.1",
  "session": "may-billing-refactor",
  "lastReviewedAt": "2026-04-15T10:45:00Z",
  "lastReviewedCommit": "abc1234def5678",
  "reviewCount": 1,
  "reviewFile": "state/reviews/PR_REVIEW_123.md",
  "verdict": "COMMENT",
  "findingsCount": 3,
  "posted": false,
  "postedAt": null,
  "status": "staged",
  "mergedAt": null
}
```

## Status Flow

```
pending -> reviewing -> staged -> posted -> merged -> cleaned
```

| Status | Set by | Meaning |
|---|---|---|
| `pending` | review Step 3 | PR discovered, not yet reviewed |
| `reviewing` | review Step 4 | Review in progress (prevents double-review) |
| `staged` | review Step 10 | Review file written, awaiting owner confirmation |
| `posted` | review Step 10/13 | Review posted to GitHub |
| `merged` | review Step 2 | PR merged, worktree ready for cleanup |
| `cleaned` | review Step 2 | Worktree removed, terminal state |

## Field Reference

| Field | Type | Description |
|---|---|---|
| `pr` | number | PR number |
| `repo` | string | Repository name (e.g., `ok-wow`) |
| `org` | string | GitHub org (e.g., `ok-wow`) |
| `title` | string | PR title |
| `author` | string | PR author login |
| `branch` | string | Head branch name |
| `taskId` | string \| null | Shipwright task ID if from todos.json |
| `session` | string \| null | Shipwright session slug |
| `lastReviewedAt` | ISO string | When the last review was performed |
| `lastReviewedCommit` | string | HEAD SHA at time of last review |
| `reviewCount` | number | How many times this PR has been reviewed |
| `reviewFile` | string | Path to PR_REVIEW markdown file |
| `verdict` | string | APPROVE or COMMENT |
| `findingsCount` | number | Number of findings in last review |
| `posted` | boolean | Whether the review has been posted to GitHub |
| `postedAt` | ISO string \| null | When the review was posted |
| `status` | string | See Status Flow above |
| `mergedAt` | ISO string \| null | When the PR was merged |

## Key Behaviors

- `lastReviewedCommit` enables "new commits since last review" detection without
  re-fetching GitHub history. Compare against `gh pr view --json headRefOid`.
- `taskId` is nullable -- PRs not from shipwright todos still get reviewed when
  `review_external_prs` is enabled in agent-policy.md.
- The `reviewing` status prevents concurrent cron runs from double-reviewing the
  same PR. If a review was interrupted (agent restart), the status stays `reviewing`
  and must be manually reset to `pending`.
