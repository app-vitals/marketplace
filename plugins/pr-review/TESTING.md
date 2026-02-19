# Testing pr-review Plugin

Manual test plan for the pr-review plugin.

## Prerequisites

- [ ] GitHub CLI installed: `gh --version`
- [ ] Authenticated: `gh auth status`
- [ ] cloud-agent CLI installed (for ca-review-prs): `ca --version`

## Test Cases

### 1. review-pr Command

**Setup**: Find an open PR in a repo you have access to.

**Test first review**:
```bash
/review-pr <pr-number>
```

**Verify**:
- [ ] Checks GitHub review history — detects no prior review → fresh mode
- [ ] Checks out PR branch
- [ ] Reads CLAUDE.md files
- [ ] Analyzes diff
- [ ] Creates `PR_REVIEW_<number>.md`
- [ ] Shows draft to user
- [ ] Stays on PR branch (doesn't checkout main)

**Test posting** (optional - will actually post):
- [ ] When requested, creates `pr_review_<number>.json`
- [ ] Posts review to GitHub
- [ ] Shows confirmation

**Test follow-up** (use a PR you've previously reviewed):
```bash
/review-pr <pr-number>
```

**Verify**:
- [ ] Checks GitHub review history — detects prior review → update mode
- [ ] Fetches your prior inline comments from GitHub API
- [ ] Identifies commits since last review
- [ ] Checks resolution status of each issue (✅/⚠️/❌)
- [ ] Appends update section to `PR_REVIEW_<number>.md`
- [ ] Shows updated recommendation

### 2. ca-review-prs Command

**Setup**: Need cloud-agent CLI installed.

**Test queue mode** (no PR numbers):
```bash
/ca-review-prs
/ca-review-prs owner/repo
```

**Verify queue mode**:
- [ ] Gets your GitHub username
- [ ] Fetches open PRs
- [ ] Filters out drafts and your own PRs
- [ ] Categorizes: review-requested, not-reviewed, updated-since-review
- [ ] Displays queue table
- [ ] Offers to queue all or select specific PRs

**Test direct mode** (with PR numbers):
```bash
/ca-review-prs 123 456
```

**Verify direct mode**:
- [ ] Checks ca CLI availability
- [ ] Queues reviews for each PR
- [ ] Monitors progress in background
- [ ] Reports completion status
- [ ] Offers to apply successful reviews

### 4. Install/Uninstall Commands

**Test install**:
```
/install-pr-review
```

**Verify**:
- [ ] Creates ~/.local/bin if needed
- [ ] Symlinks review-pr to ~/.local/bin
- [ ] Shows PATH warning if needed

**Test CLI wrapper**:
```bash
review-pr <pr-number>
```

**Verify**:
- [ ] Launches Claude with `/review-pr`
- [ ] No permission prompts for gh/git commands
- [ ] Works from any directory

**Test uninstall**:
```
/uninstall-pr-review
```

**Verify**:
- [ ] Removes review-pr symlink

### 5. Edge Cases

- [ ] Closed PR: Should inform user and stop
- [ ] Draft PR: Should ask if user wants to proceed
- [ ] Already reviewed PR: Should auto-switch to update mode
- [ ] PR with no CLAUDE.md: Should proceed without compliance check
- [ ] Invalid PR number: Should show helpful error

## Integration Tests

**Full workflow**:
1. `/ca-review-prs` - See what needs review, queue PRs
2. Apply completed reviews one by one
3. Edit draft if needed
4. Post review
5. Wait for PR update
6. `/review-pr <number>` - Follow up (auto-detected as update mode)

## Notes

- Testing posting will create real reviews on GitHub
- Use a test repo or your own PRs for safe testing
- The ca-review-prs command requires cloud-agent infrastructure
