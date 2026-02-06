---
name: review-pr-update
description: Follow-up review checking if previous comments were addressed after PR updates
argument-hint: "<pr-number>"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

# Pull Request Review Update

Update the review for pull request: $ARGUMENTS

## Context

This command is for follow-up reviews after a PR has been updated. It references your previous review (from this conversation or from PR_REVIEW_<number>.md) to check if comments were addressed.

## Setup

1. **Load previous review**:
   - Check conversation history for prior review of this PR
   - Read `PR_REVIEW_<number>.md` if it exists
   - If no previous review found, suggest using `/review-pr` instead

2. **Fetch current PR state**:
   ```bash
   gh pr view <number> --json number,title,state,headRefName,commits,updatedAt
   ```

3. **Checkout latest code**:
   ```bash
   gh pr checkout <number>
   ```

## Identify Changes

4. **Find new commits** since your review:
   ```bash
   gh pr view <number> --json commits
   ```
   - Compare commit timestamps with your review date
   - List commits added after your review

5. **Get the latest diff**:
   ```bash
   gh pr diff <number>
   ```
   For file counts, use `gh pr diff <number> --name-only | wc -l` (not `git checkout` output, which shows local branch changes).

6. **Check for new comments**:
   ```bash
   gh pr view <number> --json comments,reviews
   ```
   - Note any discussion since your review
   - Check if author responded to your comments

## Verify Comment Resolution

7. **For each issue from your original review**, check:

   - ✅ **Addressed**: Fixed/implemented as suggested
   - ⚠️ **Partially addressed**: Some progress but incomplete
   - ❌ **Not addressed**: Still needs attention
   - 🔄 **Changed approach**: Different solution, evaluate if acceptable

   Provide specific evidence (file:line references) for each assessment.

## Review New Code

8. **Analyze new additions**:
   - Identify new features, functions, or code blocks added since original review
   - These may be addressing feedback OR new work added to the PR
   - Apply the same review criteria as original review:
     - CLAUDE.md compliance
     - Bug detection
     - Error handling
     - Test coverage

9. **Score new issues** with confidence levels (same scale as original review).

## Append Update to Review File

10. **Append to `PR_REVIEW_<number>.md`**:

    ```markdown

    ---

    ## Review Update - <date>

    ### Commits Since Last Review

    - <commit sha>: <commit message>
    - ...

    ### Comment Resolution Status

    #### From Original Review

    | Issue | Status | Evidence |
    |-------|--------|----------|
    | <issue 1> | ✅ Addressed | Fixed in `file.ts:45` |
    | <issue 2> | ⚠️ Partial | Logging added but no error ID |
    | <issue 3> | ❌ Not addressed | Still missing validation |

    ### New Issues Found

    #### Critical Issues (X found)
    ...

    #### Important Issues (X found)
    ...

    ### CI Status

    <current status>

    ### Updated Recommendation

    <APPROVE / REQUEST_CHANGES / COMMENT>

    **Previous**: <previous recommendation>
    **Now**: <updated recommendation with reasoning>
    ```

11. **Present to user**:
    - Show the update summary
    - Highlight what changed in your recommendation
    - Ask if they want to post an updated review

## Posting Updated Review

12. **When user requests posting**:
    - Follow same process as `/review-pr`
    - Create new review JSON
    - Submit via GitHub API
    - Note: This creates a new review, doesn't update the old one

## Important Notes

- **Reference previous review**: Always tie back to original findings
- **Stay on PR branch**: Continue enabling follow-up questions
- **Append, don't overwrite**: Keep history of review iterations
- **Be specific**: Show exact file:line evidence for resolution status
- **Review quality**: Apply the same standards as `/review-pr` — verify before flagging, no filler language, keep it tight, organize by file/line

## Usage

```bash
/review-pr-update 123
```

Best used after:
1. You ran `/review-pr 123` earlier
2. PR author pushed updates
3. You want to verify your comments were addressed
