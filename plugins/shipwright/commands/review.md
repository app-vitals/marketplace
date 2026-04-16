---
description: Review open PRs -- deep single-pass review with inline comments, policy-controlled posting and merging
allowed-tools: Bash, Read, Write, Glob, Grep, Agent
argument-hint: "[org/repo#number]"
---

# Review

Review open PRs with policy-controlled posting. Reviews are staged for owner
confirmation by default.

---

## Arguments

Parse `$ARGUMENTS`:
- `org/repo#number` (e.g. `app-vitals/vitals-os#123`): target a specific PR. If a staged
  review exists in `state/reviews.json`, post it. Otherwise, review it.
- `number` or `#number`: same, using the default repo from `state/todos.json`
- No arguments: normal review flow — find the next PR to review from the queue

---

## Step 1: Load Policy

Read `state/agent-policy.md`. If the file doesn't exist, use these conservative defaults:

| Setting | Default |
|---------|---------|
| `auto_post_reviews` | false |
| `allowed_events` | [COMMENT, APPROVE] |
| `review_shipwright_prs` | true |
| `review_external_prs` | true |
| `min_confidence` | 75 |
| `max_findings` | 5 |
| `auto_merge` | false |
| `require_human_approval` | true |
| `auto_fix_review_findings` | false |
| `cleanup_merged_worktrees` | true |
| `cleanup_after_days` | 14 |

Print a one-line policy summary:
```
Policy: {staging|auto-posting} reviews, {no auto-merge|auto-merge enabled}, {shipwright PRs only|all open PRs}
```

---

## Step 2: Clean Up Worktrees

If `cleanup_merged_worktrees` is true:

1. Read `state/reviews.json` (create as `[]` if missing)
2. For entries with `status` of `staged`, `posted`, or `reviewing`:
   - Check if the PR is merged or closed: `gh pr view {pr} --repo {org}/{repo} --json state -q '.state'`
   - If `MERGED` or `CLOSED`: remove the worktree if it exists (`git -C repos/{repo} worktree remove worktrees/{repo}-{branch-slug} --force 2>/dev/null`), update `status: "merged"`, set `mergedAt`
3. For entries with `status: "merged"`: set `status: "cleaned"` (terminal)
4. Remove stale worktrees older than `cleanup_after_days`:
   ```bash
   find worktrees/ -maxdepth 1 -type d -mtime +{cleanup_after_days} -exec basename {} \;
   ```
   For each, remove via `git worktree remove`.
5. Write updated `state/reviews.json`
6. If any cleaned: print `Cleaned {N} worktrees`

---

## Step 3: Find PRs to Review

Build the review queue from two sources.

### Source A: Shipwright Todos (if `review_shipwright_prs` is true)

Read `state/todos.json`. Find tasks with `source: "shipwright"` and `status: "pr_open"`.
For each, extract `pr`, `repo`, `session`, `id` (task ID).

### Source B: External PRs (if `review_external_prs` is true)

For each configured repo:
```bash
gh pr list --state open --repo {org}/{repo} \
  --json number,title,author,headRefName,baseRefName,isDraft,reviews,updatedAt
```

Exclude:
- Draft PRs
- PRs authored by this agent
- PRs already in Source A

### Deduplication and Filtering

Read `state/reviews.json`. For each candidate PR:

- **No entry**: eligible (new PR)
- **Entry with `status: "reviewing"`**: skip (another run is working on it)
- **Entry with `status: "staged"` or `"posted"`**: check for new commits since last review:
  ```bash
  gh pr view {pr} --repo {org}/{repo} --json headRefOid -q '.headRefOid'
  ```
  If `headRefOid` differs from `lastReviewedCommit`: eligible for re-review.
  If same: skip.
- **Entry with `status: "cleaned"` or `"merged"`**: skip.

Also skip if another reviewer has unresolved substantive feedback the author hasn't
addressed -- check existing reviews and comments:
```bash
gh pr view {pr} --repo {org}/{repo} --json reviews,comments
```
If there are CHANGES_REQUESTED reviews from others with no subsequent commits, skip.

### Pick Next PR

From eligible candidates, pick the oldest (by `createdAt` or `firstSeen`).

If nothing to review:
```
No PRs need review.
```
Stop (with `[silent]` marker for cron).

---

## Step 4: Checkout into Worktree

```bash
git -C repos/{repo} fetch origin
git -C repos/{repo} worktree add worktrees/{repo}-{branch-slug} origin/{branch}
```

Branch slug = branch name with `/` replaced by `-`.

If the worktree already exists (prior interrupted run):
```bash
git -C repos/{repo} worktree remove worktrees/{repo}-{branch-slug} --force
git -C repos/{repo} worktree add worktrees/{repo}-{branch-slug} origin/{branch}
```

Update `state/reviews.json`: add or update the entry with `status: "reviewing"`.

All subsequent steps run from `worktrees/{repo}-{branch-slug}/`.

---

## Step 5: Gather Context

1. **PR metadata**:
   ```bash
   gh pr view {pr} --repo {org}/{repo} \
     --json number,title,author,headRefName,baseRefName,headRefOid,additions,deletions,changedFiles,body
   ```

2. **Diff against the correct base branch** (not always main):
   ```bash
   base=$(gh pr view {pr} --repo {org}/{repo} --json baseRefName -q '.baseRefName')
   git diff "$base"...HEAD
   ```

3. **Changed files**: extract from the diff

4. **CI status** via Actions API (not `gh pr checks` -- broken with PATs):
   ```bash
   gh api "repos/{org}/{repo}/actions/runs?branch={branch}&per_page=5" \
     -q '.workflow_runs[] | "\(.name): \(.status) \(.conclusion)"'
   ```

5. **Existing reviews and comments**:
   ```bash
   gh pr view {pr} --repo {org}/{repo} --json comments,reviews
   ```

6. **CLAUDE.md files**: read root CLAUDE.md + CLAUDE.md files in directories containing changed files

If another reviewer has unresolved substantive feedback that was missed in Step 3:
update `state/reviews.json` status back to `pending`, skip this PR, try the next.

---

## Step 6: Deep Review

Single-pass review. For each changed file:

1. **Read the full file** (not just the diff) for complete context
2. Check CLAUDE.md compliance
3. Look for:
   - Bugs and logic errors
   - Edge cases and off-by-ones
   - Error handling gaps (swallowed errors, missing validation)
   - Security issues (injection, auth bypass, exposed secrets)
   - Silent failures and inappropriate fallbacks
   - **Breaking API changes** -- assume rolling deployments where clients and servers
     don't deploy atomically. Flag removed endpoints, changed request/response shapes,
     renamed fields as critical.
4. If the PR maps to a shipwright task with `acceptanceCriteria`: verify each criterion
   is satisfied by the diff

---

## Step 7: Score and Classify Findings

For each finding, assign confidence (0-100):

| Range | Category | Meaning |
|-------|----------|---------|
| 90-100 | Critical | Bug, CLAUDE.md violation, breaking API change |
| 75-89 | Important | Likely to cause problems |
| 50-74 | Suggestion | Valid concern, lower impact |
| < 50 | Discard | Nitpick or false positive |

**Before including any finding, verify it:**

- Read the actual source file to confirm (not just the diff)
- Check if pre-existing on base: `git show {base}:{file}` -- if the issue exists
  on the base branch, it's out of scope. Drop it.
- Don't echo CI failures -- the author can see those
- Don't flag patterns the project's CLAUDE.md explicitly endorses
- Don't suggest fixes the author didn't ask for -- call out the problem, optionally
  suggest a fix

Apply policy thresholds:
- Drop findings below `min_confidence` (default 75)
- Trim to `max_findings` (default 5), removing lowest confidence first

**Keep it tight.** A good review has 2-5 actionable items. Drop low-confidence
suggestions and nitpicks.

---

## Step 8: Write Review File

Write `state/reviews/PR_REVIEW_{pr}.md`:

```markdown
# PR Review: #{pr} - {title}

**Author**: @{author}
**Branch**: {head} -> {base}
**Date**: {date}
**Reviewed commit**: {head_sha}

## Summary

{Brief description of what this PR does}

## CI Status

{Current status of checks}

## Critical Issues ({count})

### 1. {Issue title}
- **File**: `path/to/file.ts:123`
- **Confidence**: 95
- **Issue**: {description}
- **Suggestion**: {fix, if applicable}

## Important Issues ({count})

### 1. {Issue title}
...

## Suggestions ({count})

- {suggestion with file:line reference}

## Strengths

- {What's done well -- keep brief}

## Recommendation

{APPROVE or COMMENT}
{One-sentence reasoning}
```

### Re-Review (Update)

If this PR was reviewed before (entry in reviews.json with `reviewCount >= 1`):

Append an update section instead of creating a new file:

```markdown
---

## Review Update - {date}

### New Commits Since Last Review

- {sha}: {message}

### Prior Findings Resolution

| Finding | Status | Evidence |
|---------|--------|----------|
| {issue 1} | Addressed | Fixed in `file.ts:45` |
| {issue 2} | Partial | Logging added but no error ID |
| {issue 3} | Not addressed | Still missing validation |

### New Issues ({count})
...

### Updated Recommendation

{APPROVE or COMMENT}
**Previous**: {previous verdict}
**Now**: {updated verdict with reasoning}
```

---

## Step 9: Build Review JSON

Follow `references/post-review-guide.md` for the full mechanics.

Write `state/reviews/pr_review_{pr}.json`:

```json
{
  "commit_id": "{head_sha}",
  "body": "{concise verdict}",
  "event": "APPROVE|COMMENT",
  "comments": [
    {
      "path": "path/to/file.ts",
      "line": 123,
      "side": "RIGHT",
      "body": "Comment text"
    }
  ]
}
```

**Diff-line mapping**: for each finding with a `file:line` reference, check if the
line is in the diff (`git diff {base}...HEAD -- {file}`). Only lines within diff
hunks are valid for inline comments. Move others to the review body.

**Event selection** (from policy `allowed_events`):
- COMMENT: broken behavior, missing functionality, functional gaps, security
- APPROVE: style issues, nits, optional suggestions, or clean PR
- If any finding indicates something that should be fixed before shipping: COMMENT
- Never REQUEST_CHANGES

---

## Step 10: Post or Stage

### If `auto_post_reviews` is true (policy):

1. Submit via GitHub API:
   ```bash
   gh api -X POST /repos/{org}/{repo}/pulls/{pr}/reviews \
     --input state/reviews/pr_review_{pr}.json
   ```
2. Capture `html_url` from response
3. Update `state/reviews.json`: `posted: true`, `postedAt: now`, `status: "posted"`
4. Print: `Posted review for #{pr}: {html_url}`

### If `auto_post_reviews` is false (default):

1. Update `state/reviews.json`: `status: "staged"`
2. Post Slack message to the configured channel:
   ```
   Review ready for #{pr} ({repo}): {title}
   Verdict: {APPROVE|COMMENT} -- {findingsCount} findings
   Review: state/reviews/PR_REVIEW_{pr}.md
   Post with: /shipwright:review {org}/{repo}#{pr}
   ```
3. Print: `Review staged for #{pr}. Slack notification sent.`

---

## Step 11: Update reviews.json

Update the entry for this PR:

```json
{
  "lastReviewedAt": "{now}",
  "lastReviewedCommit": "{head_sha}",
  "reviewCount": "{increment}",
  "reviewFile": "state/reviews/PR_REVIEW_{pr}.md",
  "verdict": "{APPROVE|COMMENT}",
  "findingsCount": "{count}",
  "posted": "{true|false}",
  "postedAt": "{timestamp|null}",
  "status": "{staged|posted}"
}
```

Write `state/reviews.json`.

---

## Step 12: Enrich Metrics (if shipwright task)

If the PR maps to a task in `state/todos.json` (via `taskId`):

1. Find the task's planning folder: `planning/{session}/`
2. Read `planning/{session}/metrics.jsonl`
3. Find the line matching this task ID
4. Add the `review` object:
   ```json
   "review": {
     "verdict": "{verdict}",
     "findings": {findingsCount},
     "fixes_applied": 0,
     "agents": ["single-pass"]
   }
   ```
5. Write back

If the verdict is APPROVE and `auto_post_reviews` is true: update `state/todos.json`
to set `status: "approved"`.

Resolve PostHog script (silent):
```bash
POSTHOG_SCRIPT=$(find ~/.claude/plugins/cache -name "posthog_send.py" -path "*/shipwright/*" 2>/dev/null | head -1)
```

If set, fire `shipwright_task_reviewed`:
```bash
python3 "$POSTHOG_SCRIPT" shipwright_task_reviewed \
  --project {repo} --task {taskId} \
  pr={pr} verdict={verdict} findings={findingsCount}
```

---

## Step 13: Targeted PR (argument provided)

When invoked with a specific PR (e.g. `/shipwright:review app-vitals/vitals-os#123` or
`/shipwright:review 123`):

1. Parse the argument: extract `org`, `repo`, and `pr` number. For bare numbers,
   infer `org/repo` from `state/todos.json` (the repo of the first shipwright task)
   or from the current workspace repo.
2. Read `state/reviews.json`, find the entry for this PR.

**If entry exists with `status: "staged"`** — post it:
3. Read `state/reviews/pr_review_{pr}.json`
4. Submit:
   ```bash
   gh api -X POST /repos/{org}/{repo}/pulls/{pr}/reviews \
     --input state/reviews/pr_review_{pr}.json
   ```
5. Capture `html_url`
6. Update `state/reviews.json`: `posted: true`, `postedAt: now`, `status: "posted"`
7. Print: `Posted review for #{pr}: {html_url}`
8. If the PR maps to a shipwright task and verdict is APPROVE: update `state/todos.json`
   to set `status: "approved"`

**If no entry or entry is not staged** — review it:
3. Skip Step 3 (queue building) and go directly to Step 4 (checkout) with this
   specific PR as the target.

---

## Review Quality Rules

These rules are non-negotiable regardless of policy settings:

- **Verify before flagging**: check actual code, not just the diff. Confirm library
  versions, check if both branches of a conditional do the same thing.
- **Check scope**: `git show {base}:{file}` -- if the issue exists on the base branch,
  it's out of scope.
- **Don't echo CI**: don't call out failing tests unless confident your findings are
  the cause.
- **Don't contradict CLAUDE.md**: don't suggest patterns the project explicitly avoids.
- **No filler language**: no "FYI", "Note:", "Just a heads up". Be direct.
- **Keep it tight**: 2-5 actionable items. Drop low-confidence suggestions and nitpicks.
- **Organize by file and line**: list issues in diff order.
- **Never REQUEST_CHANGES**: only APPROVE or COMMENT.
- **Check teammate comments first**: don't approve over substantive unresolved feedback
  from others.
- **Concise approvals**: if all items are addressed with no new issues, a brief APPROVE
  to unblock is more valuable than a detailed duplicate review.
- **Breaking API changes**: assume rolling deployments. Flag removed endpoints, changed
  shapes, renamed fields as critical.
