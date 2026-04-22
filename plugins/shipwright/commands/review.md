---
description: Review open PRs -- deep single-pass review with inline comments, policy-controlled posting and merging
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

Before building the queue, resolve the current GitHub CLI user once and remember the value — substitute it directly into all subsequent commands that need it:

```bash
gh api /user -q '.login'
```

### Step 3a: Drain Staged Queue (interactive mode)

Read `state/reviews.json` for entries with `status: "staged"`.

If any staged reviews exist, present them in priority order:
1. **APPROVE verdicts first** — unblocking is highest value
2. **Then by `diffSize` ascending** — smallest diffs are fastest to confirm

Display:
```
## Staged Reviews ({N})
| PR | Repo | Title | Verdict | Diff | Staged |
|----|------|-------|---------|------|--------|
| #123 | vitals-os | Add feature X | APPROVE | +45/-12 (57) | 2h ago |
| #456 | vitals-os | Fix bug Y | COMMENT | +120/-30 (150) | 1h ago |

Post staged reviews, or skip to new reviews?
```

**If posting**: work through them one at a time using the Step 14 posting mechanics
(show review summary → confirm → post → move to next). After all staged reviews are
processed or skipped, continue to Step 3b.

**If skipping**: proceed directly to Step 3b.

---

### Step 3b: Build Review Queue

Build the review queue from two sources.

### Source A: Shipwright Todos (if `review_shipwright_prs` is true)

Read `state/todos.json`. Find tasks with `source: "shipwright"` and `status: "pr_open"`.
For each, extract `pr`, `repo`, `session`, `id` (task ID).

Exclude tasks where the PR author matches `CURRENT_USER` — you can't review your own PRs.
Check the author via:
```bash
gh pr view {pr} --repo {org}/{repo} --json author -q '.author.login'
```

### Source B: External PRs (if `review_external_prs` is true)

For each configured repo:
```bash
gh pr list --state open --repo {org}/{repo} \
  --json number,title,author,headRefName,baseRefName,isDraft,reviews,updatedAt,additions,deletions
```

Exclude:
- Draft PRs
- PRs where `author.login == CURRENT_USER` (can't review your own PRs)
- PRs already in Source A

### Deduplication and Filtering

Read `state/reviews.json`. For each candidate PR:

- **No entry**: eligible (new PR). Create a `pending` entry immediately:
  ```json
  {
    "pr": {number}, "repo": "{repo}", "org": "{org}",
    "title": "{title}", "author": "{author.login}", "branch": "{headRefName}",
    "additions": {additions}, "deletions": {deletions},
    "diffSize": {additions + deletions},
    "firstSeen": "{now ISO}", "status": "pending"
  }
  ```
- **Entry with `status: "reviewing"`**: skip (another run is working on it)
- **Entry with `status: "staged"` or `"posted"`**: check for new commits since last review:
  ```bash
  gh pr view {pr} --repo {org}/{repo} --json headRefOid -q '.headRefOid'
  ```
  If `headRefOid` differs from `lastReviewedCommit`: potentially eligible for re-review —
  but also check whether prior comments are resolved (see below).
  If same: skip.
- **Entry with `status: "cleaned"` or `"merged"`**: skip.

If a `pending` entry is missing `diffSize` (created before this field was added), populate
it from the Source B fetch before sorting.

#### Prior Comment Resolution Check (re-reviews only)

For any PR eligible for re-review (`reviewCount >= 1`), check whether the inline comments
from the previous review have been resolved before reviewing again:

```bash
gh api graphql -f query='
{
  repository(owner: "{org}", name: "{repo}") {
    pullRequest(number: {pr}) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          comments(first: 1) {
            nodes {
              author { login }
            }
          }
        }
      }
    }
  }
}'
```

Count threads where `comments[0].author.login == CURRENT_USER` and `isResolved == false`.
If any such unresolved threads exist: **skip this PR**. The author needs to address the
previous findings first. Print: `Skipping #{pr} — {N} prior comment(s) unresolved.`

If all prior threads are resolved (or there were no inline comments), proceed with re-review.

#### Teammate Comment Check

Fetch reviews and comment timeline:
```bash
gh pr view {pr} --repo {org}/{repo} --json reviews,comments,commits
```

A **substantive teammate comment** is one where ALL of the following are true:
- Author login does not contain `[bot]` and is not a known CI account
- Body is not a trivial acknowledgement: not "LGTM", "+1", "thanks", "approved", or emoji-only
- The comment was posted **after** the most recent commit push date (the author has not pushed since)

Skip this PR if **any** of the following are true:
- A teammate (not `CURRENT_USER`, not a bot) has a `CHANGES_REQUESTED` review with no commits since that review
- A teammate has a substantive comment with no commits since that comment

Print: `Skipping #{pr} — unresolved teammate feedback from @{login} ({type} on {date}). No commits since.`

### Pick Next PR

From eligible candidates, sort by `diffSize` ascending (smallest diff first). Pick the
first. For ties or missing `diffSize`, fall back to `firstSeen` ascending.

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

Apply the teammate comment check from Step 3 using the fetched `reviews` and `comments`
(they were just fetched above — no extra API call needed). If any substantive unresolved
teammate feedback is found: update `state/reviews.json` status to `pending`, skip this PR,
and return to Step 3b to pick the next candidate.

---

## Step 6: Classify Changes by Domain

Before reading individual files, build a structural picture of what kind of work this PR does. Work from the PR body, commit messages, and file list:

- **Why**: What problem is this solving? What's the motivation? (PR body, linked issues, commit messages)
- **What changed**: High-level summary of affected areas — which features, services, or layers are touched
- **Web view changes**: Any new or modified pages, components, or UI flows — identify business logic changes, not just layout tweaks
- **API changes**: New, removed, or modified endpoints; changed request/response shapes; auth changes; new event streams (SSE, WebSocket)
- **Database changes**: New tables or columns, dropped columns, index changes, migrations, schema-affecting model changes
- **Architecture changes**: New services or packages, new ways of exposing functionality (new route groups, new event types, new integrations), changes to service boundaries

Note which categories are present (even if "none") — this drives review focus and the Slack summary.

---

## Step 7: Deep Review (dispatch `shipwright:code-reviewer` subagent)

Delegate the per-file review to the bundled `shipwright:code-reviewer` subagent. This
keeps review context isolated from the main thread (policy, queue, posting).

Dispatch via the Agent tool with `subagent_type: "shipwright:code-reviewer"` and pass
a single prompt block containing:

- **PR metadata** — `number`, `title`, `author`, `headRefName`, `baseRefName`, `headRefOid`
- **Full diff** — the `git diff "$base"...HEAD` output from Step 5.2
- **Changed files** — the list extracted in Step 5.3
- **CLAUDE.md contents** — root CLAUDE.md + any CLAUDE.md in directories containing
  changed files (from Step 5.6). Include each as a labeled block so the subagent knows
  which directory it governs.
- **`acceptanceCriteria`** — if the PR maps to a shipwright task, paste the criteria;
  otherwise omit the field
- **Policy** — pass `min_confidence` and `max_findings` from Step 1

The subagent returns a JSON object with `summary`, `findings[]`, `strengths[]`,
`recommendation`, and `recommendation_reason`. Parse it and carry the data into Step 8.

If the subagent returns malformed JSON, retry once with a reminder of the schema. If it
still fails, fall back to an inline review in the main thread using the same rules
(see `agents/code-reviewer.md` for the canonical rule set).

---

## Step 8: Score and Classify Findings

The subagent has already applied confidence scoring and verification (pre-existing
filter, CLAUDE.md endorsement check, silent-failure detection, breaking-API rule,
acceptance-criteria check). This step applies policy thresholds from `state/agent-policy.md`.

| Range | Category | Meaning |
|-------|----------|---------|
| 90-100 | Critical | Bug, CLAUDE.md violation, breaking API change |
| 75-89 | Important | Likely to cause problems |
| 50-74 | Suggestion | Valid concern, lower impact |
| < 50 | Discard | Nitpick or false positive |

Apply policy thresholds to the subagent's `findings[]`:
- Drop findings below `min_confidence` (default 75)
- Trim to `max_findings` (default 5), removing lowest confidence first
- Group remaining findings by their `severity` field (`critical`, `important`, `suggestion`)

**Keep it tight.** A good review has 2-5 actionable items. If the subagent returned
more, trim to the highest-confidence few.

---

## Step 9: Write Review File

Write `state/reviews/PR_REVIEW_{pr}.md`:

```markdown
# PR Review: #{pr} - {title}

**Author**: @{author}
**Branch**: {head} -> {base}
**Date**: {date}
**Reviewed commit**: {head_sha}

## Summary

{Brief description of what this PR does}

## Change Summary

**Why**: {motivation — problem being solved or feature being delivered}

**What changed**: {high-level summary of affected areas}

**Web view changes**: {new/modified pages or UI flows with business logic impact, or "none"}

**API changes**: {new, removed, or modified endpoints; shape changes; new event mechanisms (SSE, WebSocket), or "none"}

**Database changes**: {schema changes — tables, columns, indexes, migrations, or "none"}

**Architecture changes**: {new services, new ways of exposing functionality, service boundary changes, or "none"}

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

## Step 10: Build Review JSON

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

## Step 11: Post or Stage

### If `auto_post_reviews` is true (policy):

1. Submit via GitHub API:
   ```bash
   gh api -X POST /repos/{org}/{repo}/pulls/{pr}/reviews \
     --input state/reviews/pr_review_{pr}.json
   ```
2. Capture `html_url` from response
3. Update `state/reviews.json`: `posted: true`, `postedAt: now`, `status: "posted"`
4. Print: `Posted review for #{pr}: {html_url}`
5. Post Slack message (see below)

### If `auto_post_reviews` is false (default):

1. Update `state/reviews.json`: `status: "staged"`
2. Post Slack message to the configured channel (see below)
3. Print: `Review staged for #{pr}. Slack notification sent.`

### Slack Message (both paths)

Send to the configured engineering channel:

```
*PR #{pr}: {title}*
{url}

*Why:* {motivation from Change Summary}

*What changed:*
{high-level summary from Change Summary}

*Web view changes:* {value or "none"}
*API changes:* {value or "none"}
*Database changes:* {value or "none"}
*Architecture changes:* {value or "none"}

*Verdict:* {APPROVE|COMMENT} — {one-line reasoning}
{if staged: Post with: /shipwright:review {org}/{repo}#{pr}}
```

Use the Slack MCP tool if available. If no Slack integration is configured, print the formatted message.

---

## Step 12: Update reviews.json

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

## Step 13: Enrich Metrics (if shipwright task)

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

## Step 14: Targeted PR (argument provided)

When invoked with a specific PR (e.g. `/shipwright:review app-vitals/vitals-os#123` or
`/shipwright:review 123`):

1. Parse the argument: extract `org`, `repo`, and `pr` number. For bare numbers,
   infer `org/repo` from `state/todos.json` (the repo of the first shipwright task)
   or from the current workspace repo.
2. Read `state/reviews.json`, find the entry for this PR.

**If entry exists with `status: "staged"`** — post it:

> **Design note**: When `auto_post_reviews` is false, the cron stages reviews and
> notifies the owner. Explicitly targeting a staged PR (`/shipwright:review {pr}`) IS
> the posting confirmation — the owner ran the command knowing a review is staged.
> No additional confirmation prompt is needed; targeted invocation is the approval gesture.

**2a. Re-fetch for new teammate feedback** before posting:
```bash
gh pr view {pr} --repo {org}/{repo} --json reviews,comments,commits
```
Apply the teammate comment check from Step 3, but restricted to feedback that arrived
**after `lastReviewedAt`** in the reviews.json entry.

If any substantive teammate comments or `CHANGES_REQUESTED` reviews arrived since the
review was staged:
- Update `state/reviews.json`: `status: "needs-rereview"`, `needsRereviewReason: "{summary}"`
- Print:
  ```
  Not posting — new teammate feedback arrived since the review was staged:
  - @{login} ({date}): "{first 120 chars of body}"
  ...
  Status set to needs-rereview. Re-run /shipwright:review {org}/{repo}#{pr} after the author responds.
  ```
- Stop.

3. Read `state/reviews/PR_REVIEW_{pr}.md` and extract the verdict and findings summary
4. Print what is about to be posted so the owner can see it before the API call fires:
   ```
   Posting staged review for #{pr}: {title}
   Verdict: {APPROVE|COMMENT} — {findingsCount} findings
   {One-line key findings summary, or "No blocking issues" if clean}
   Review file: state/reviews/PR_REVIEW_{pr}.md
   ```
5. Read `state/reviews/pr_review_{pr}.json`
6. Submit:
   ```bash
   gh api -X POST /repos/{org}/{repo}/pulls/{pr}/reviews \
     --input state/reviews/pr_review_{pr}.json
   ```
7. Capture `html_url`
8. Update `state/reviews.json`: `posted: true`, `postedAt: now`, `status: "posted"`
9. Print: `Posted review for #{pr}: {html_url}`
10. Post Slack message using the format from Step 11
11. If the PR maps to a shipwright task and verdict is APPROVE: update `state/todos.json`
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
