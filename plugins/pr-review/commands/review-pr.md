---
name: review-pr
description: Review a GitHub pull request with local draft, CLAUDE.md compliance checking, and iterative refinement before posting
argument-hint: "<pr-number-or-url>"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

# Pull Request Review

Review this pull request: $ARGUMENTS

## Setup

1. **Get reviewer identity**:
   ```bash
   gh auth status
   ```
   Extract the GitHub username for tracking your reviews.

2. **Extract PR details**:
   - Parse PR number from URL or arguments
   - Fetch PR metadata: `gh pr view <number> --json number,title,author,state,isDraft,baseRefName,headRefName,url,body,additions,deletions,changedFiles`

3. **Eligibility check**:
   - If PR is closed, inform user and stop
   - If PR is a draft, ask user if they want to proceed
   - Check if you've already reviewed: `gh pr view <number> --json reviews`

## Analysis

4. **Checkout the PR branch**:
   ```bash
   gh pr checkout <number>
   ```
   Stay on this branch throughout the review for follow-up questions.

5. **Gather context**:
   - Get the base branch: `gh pr view <number> --json baseRefName -q '.baseRefName'`
   - Get the diff against the base branch: `git diff <base>...HEAD` (not always main — PRs may target feature branches)
   - List changed files: `gh pr view <number> --json files`
   - Check CI status: `gh pr checks <number>`
   - Read existing comments: `gh pr view <number> --json comments,reviews`

6. **Find and read CLAUDE.md files**:
   - Read root CLAUDE.md if it exists
   - Find CLAUDE.md files in directories containing changed files
   - Note relevant patterns, conventions, and requirements

7. **Deep review** - For each changed file:
   - Read the full file for context (not just the diff)
   - Check adherence to CLAUDE.md guidelines
   - Look for bugs, logic errors, edge cases
   - Assess error handling and security
   - Check test coverage if tests exist
   - Note code quality and maintainability
   - **Check for breaking API changes**: Assume rolling deployments - clients and servers rarely deploy atomically. Flag any breaking changes (removed endpoints, changed request/response shapes, renamed fields) as critical issues.

## Issue Classification

8. **Score each issue** on confidence (0-100):
   - **90-100**: Critical bug or explicit CLAUDE.md violation
   - **75-89**: Important issue, likely to cause problems
   - **50-74**: Valid concern but lower impact
   - **Below 50**: Nitpick or possible false positive

9. **Categorize findings**:
   - **Critical Issues** (confidence 90+): Must fix before merge
   - **Important Issues** (confidence 75-89): Should fix
   - **Suggestions** (confidence 50-74): Consider fixing
   - **Positive observations**: What's done well

## Draft Review

10. **Write review to file**: `PR_REVIEW_<number>.md`

    This file is a **draft for the reviewer** (the `gh auth` user) to iterate on before posting. Write in a collaborative tone - Claude is presenting findings to the reviewer for discussion.

    Format:
    ```markdown
    # PR Review: #<number> - <title>

    **Author**: @<author>
    **Reviewer**: @<your-username>
    **Branch**: <head> → <base>
    **Date**: <date>

    ## Summary

    <Brief description of what this PR does>

    ## CI Status

    <Current status of checks>

    ## Critical Issues (X found)

    ### 1. <Issue title>
    - **File**: `path/to/file.ts:123`
    - **Confidence**: 95
    - **Issue**: <description>
    - **CLAUDE.md**: <relevant guideline if applicable>
    - **Suggestion**: <how to fix>

    ## Important Issues (X found)

    ### 1. <Issue title>
    ...

    ## Suggestions (X found)

    - <suggestion with file:line reference>

    ## Strengths

    - <What's done well>

    ## Recommendation

    <APPROVE / COMMENT>
    <Summary reasoning>
    ```

11. **Present to user**:
    - Show the draft review
    - Ask: "Review draft saved to PR_REVIEW_<number>.md. Would you like to:"
      - Edit the review
      - Post as-is
      - Discuss specific points
      - Skip posting

## Posting the Review

12. **When user requests posting**, use the `post-review` skill to submit the review to GitHub. It handles building the review JSON, mapping inline comments to diff lines, and submitting via `gh api`.

## Review Quality

- **Verify before flagging**: Check the actual codebase before raising issues. Confirm library versions (e.g. Zod 4 supports `z.enum()` with TS enums), check if both branches of a conditional do the same thing before calling a removal a concern, etc.
- **Check scope**: Before flagging a bug, check if it's pre-existing with `git show <base>:<file>`. If it exists on the base branch, it's out of scope for the PR review.
- **Cross-reference prior reviews**: Check related/parent PRs for review comments that should carry forward. API review findings often flag client-side work needed in the follow-up app PR (e.g., composite keys, event handling patterns).
- **Don't echo CI**: Don't call out failing tests unless confident your findings are the cause. CI status is visible to the author — speculating adds noise.
- **Drop CLAUDE.md contradictions**: Don't suggest comments/JSDoc if CLAUDE.md says "no comments explaining what code does." Don't suggest patterns the project explicitly avoids.
- **No filler language**: No "FYI", "Note:", "Just a heads up" in review comments. Be direct.
- **Keep it tight**: A good review has 2-5 actionable items, not 20. Drop low-confidence suggestions and nitpicks. If the review file exceeds ~50 lines of findings, it probably needs trimming.
- **Concise approvals**: If a PR already has active reviewer engagement and all items are addressed with no new issues, a concise APPROVE to unblock is more valuable than a duplicate detailed review.
- **Never REQUEST_CHANGES**: Only use APPROVE or COMMENT. REQUEST_CHANGES is too blocking — flag concerns as comments instead and let the author decide.
- **Check teammate comments first**: Before posting, read existing PR comments and reviews from teammates. Don't approve over substantive feedback without acknowledging it — if a teammate raised a valid concern, reference it in your review.
- **Organize by file and line**: List issues in diff order (matching `gh pr diff` reading order) so the reviewer can follow along. Label each with severity: critical, important, suggestion.

## Important Notes

- **Stay on PR branch**: Don't checkout main after reviewing. User may have follow-up questions.
- **Keep review files**: Retain PR_REVIEW_*.md and pr_review_*.json until PR is merged.
- **Inline comment limits**: GitHub only allows inline comments on lines that are part of the diff.
- **Iterate first**: Let user review and edit the draft before posting.
- **Use gh CLI**: All GitHub interactions should use the `gh` command.

## Usage

```bash
/review-pr 123
/review-pr https://github.com/owner/repo/pull/123
```
