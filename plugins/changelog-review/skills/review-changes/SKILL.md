---
name: review-changes
description: This skill should be used when the user asks to "review what shipped", "walk me through changes", "what changed since", "review commits", "changelog review", "catch me up on main", or wants to understand recent code changes commit-by-commit. Interactive walkthrough of git history focused on what matters to a technical lead.
---

# Review Changes

Interactive commit-by-commit walkthrough of git history for technical leads who need to understand what shipped, spot issues, and steer the team.

## When to Use

Activate when the user wants to review a range of commits to understand what changed. Typical triggers:
- "Walk me through changes since X"
- "What shipped this week?"
- "Review commits on main"
- "Catch me up"

## Workflow

### 1. Determine the Commit Range

Ask for or infer the range. Common patterns:
- A specific starting commit hash
- "Since last Friday" (resolve to a commit via `git log --after`)
- "Last N commits"
- A tag or branch point

List commits oldest-to-newest:
```
git log --oneline --reverse <start>..HEAD
```

Report the total count so the user knows how many to expect.

### 2. Present One Commit at a Time

For each commit, show the diff and summarize with this structure:

**Header:** `Commit N/total -- <hash> <subject>`

**Module:** Which service or area the change touches (e.g. "accounts", "cal (web)", "billing", "agent", "infra", "lib")

**Sections (include only those that apply):**

- **DB schema changes** -- new models, new fields, migrations. Include the field types and relationships.
- **New API endpoints** -- method, path, request/response shape, auth requirements
- **Changed API endpoints** -- what changed in behavior or response shape
- **Removed API endpoints** -- what was removed and why
- **New web pages** -- route, what it renders, key features
- **Changed web pages** -- what changed visually or behaviorally
- **Business logic** -- brief description of what the code actually does, not just what files changed

**What to skip:** Don't waste time on test-only details, planning docs, CI config, or doc updates unless the user asks. Summarize these in one line.

**Batching:** When consecutive commits are small housekeeping (docs, planning, chore), batch them into a single summary to keep momentum.

### 3. Wait for "next"

After each commit summary, stop and wait. The user may:
- Ask clarifying questions about the change
- Ask to see related code on the current branch (e.g. "how does availability.ts handle this now?")
- Request a prompt or file be written for follow-up work
- Flag an issue to discuss with the team
- Say "next" to continue

Do not auto-advance. The user controls the pace.

### 4. Handle Follow-up Requests

When the user spots something worth acting on during review:

- **Team discussion prompt:** Write a plain-text file (no markdown) to `planning/` that frames the issue, current state, proposed fix, and questions for the group. Keep it paste-ready for Slack.
- **Implementation prompt:** Write a plain-text file to `planning/` with enough context to start a new session (file paths, line numbers, what to change and why).
- **Quick fix:** If the user asks to fix something in-place, do it, but confirm first since the review session is read-oriented.

### 5. Catch Up on New Commits

If the review takes a while, more commits may land on main. When the user asks to check again:

```
git fetch origin main
git log --oneline --reverse <last-reviewed-commit>..origin/main
```

Continue the walkthrough from where it left off.

## Reading Commits

Use `git show --stat <hash>` to understand scope, then `git diff <hash>^..<hash> -- '*.ts' '*.prisma'` for the actual code changes. For large diffs, pipe through `head -300` and read the rest only if needed.

Skip non-code files (planning docs, CI yaml, docs/) in the diff unless the commit is primarily about those.

## Tone

- Concise. Lead with what changed, not how many files.
- Use the module/service vocabulary of the project (check CLAUDE.md for service ownership).
- When something looks off or inconsistent, flag it neutrally -- "This diverges from X" not "This is wrong."
- Don't editorialize unless asked. The user is forming their own opinion.

## What This Skill Is NOT

- Not a PR review tool (use `pr-review` for that)
- Not for planning work (use `shipwright` for that)
- Not for generating changelogs or release notes (this is interactive, not batch)
