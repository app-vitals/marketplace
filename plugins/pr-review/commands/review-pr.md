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
   - Get the diff: `gh pr diff <number>`
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

    <APPROVE / REQUEST_CHANGES / COMMENT>
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

12. **When user requests posting**:

    **Important**: The posted review is from the **gh auth user** (the reviewer) to the **PR author**. Reframe the tone accordingly - the draft was Claude presenting findings to the reviewer, but the posted review is the reviewer's feedback to the author.

    a. **Prepare inline comments** (if any):
       - Only lines in the diff are valid for inline comments
       - For new files: any line works
       - For modified files: only lines in diff hunks
       - If a line isn't in the diff, move comment to PR body or reference the triggering line

    b. **Create review JSON**: `pr_review_<number>.json`
       ```json
       {
         "commit_id": "<head_sha>",
         "body": "<overall review body>",
         "event": "APPROVE|REQUEST_CHANGES|COMMENT",
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

    c. **Submit review**:
       ```bash
       gh api -X POST /repos/{owner}/{repo}/pulls/{number}/reviews --input pr_review_<number>.json
       ```

    d. **Confirm success** and show link to posted review

## Approval Phrases

Use clear, concise approval language:
- "Looks good, approved"
- "Looks good, approved with comments"
- "Looks good, I have a few suggestions"
- "Awesome!" - when genuinely warranted

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
