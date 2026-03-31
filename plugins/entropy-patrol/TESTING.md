# Testing entropy-patrol

Manual test plan for entropy-patrol commands. All tests are run against a real codebase using Claude Code.

---

## entropy-scan Tests

### Test 1: Scan a clean codebase

**Setup:** Use a small repo with no obvious violations (no TODOs, all src files have tests, no hardcoded secrets, no dead exports).

**Command:** `/entropy-scan`

**Expected output:**
- Summary block prints with all zeros or very low counts
- `entropy-report.md` is written to the project root
- Report includes a "No Violations" section confirming each rule was checked
- No code files are modified

---

### Test 2: Scan a repo with a known violation

**Setup:** In a test repo, add the following to a source file:
```typescript
// TODO: fix this before release
export function unusedHelper() {}
```
Also add a `.ts` file **under `src/`** with no corresponding `.test.ts`.

**Command:** `/entropy-scan`

**Expected output:**
- `todo_fixme_hack` rule fires and reports the TODO at the correct file + line
- `dead_exports` rule fires and flags `unusedHelper` if it has no import sites
- `missing_test_file` rule fires and flags the untested source file
- All findings appear as `- [ ]` checkboxes in `entropy-report.md`
- Summary block shows non-zero counts

---

### Test 3: `--init` flag on a repo with no config

**Setup:** Confirm `.claude/entropy-patrol/golden-principles.yaml` does NOT exist in the project.

**Command:** `/entropy-scan --init`

**Expected output:**
- File is created at `.claude/entropy-patrol/golden-principles.yaml`
- Contents match the plugin default `skills/entropy-scan/golden-principles.yaml`
- Message: "Created `.claude/entropy-patrol/golden-principles.yaml`. Edit it to customize..."
- **No scan is run** — skill exits after creating the file
- No `entropy-report.md` is written

---

### Test 4: `--init` flag when config already exists

**Setup:** Create `.claude/entropy-patrol/golden-principles.yaml` with custom content.

**Command:** `/entropy-scan --init`

**Expected output:**
- Message: "Config already exists at `.claude/entropy-patrol/golden-principles.yaml`..."
- Existing file is **not overwritten**
- **No scan is run**

---

### Test 5: `--summary` flag

**Setup:** Use any repo (with or without violations).

**Command:** `/entropy-scan --summary`

**Expected output:**
- Summary block prints to stdout (severity counts and top issues)
- **No `entropy-report.md` is written**
- No entry appended to `.entropy-patrol/quality-log.jsonl`
- Message at bottom confirms report was skipped

---

### Test 6: Project-level config overrides plugin default

**Setup:**
1. Run `/entropy-scan --init` to create `.claude/entropy-patrol/golden-principles.yaml`
2. Edit the file to disable one rule: add `disabled: true` to `dead_exports`

**Command:** `/entropy-scan`

**Expected output:**
- Output header shows "Using project config: `.claude/entropy-patrol/golden-principles.yaml`"
- `dead_exports` rule does NOT appear in the report (neither in findings nor in "No Violations" section)
- All other enabled rules run normally

---

### Test 7: Repo with no source files

**Setup:** Run in an empty directory or a repo with only config files (no `src/` dir).

**Command:** `/entropy-scan`

**Expected output:**
- Scan completes without crashing
- Report shows "No violations" or very low counts
- No error messages about missing directories

---

### Test 8: Hardcoded secret detection (security rule)

**Setup:** Add to a source file:
```typescript
const apiKey = "sk-abc123def456ghi789jkl012";
```

**Command:** `/entropy-scan`

**Expected output:**
- `hardcoded_secrets` rule fires
- Finding appears under the `security` category with `high` severity
- File path and approximate line number are reported
- Summary block shows at least 1 high-severity finding
- The `⚠️ Run /entropy-fix` message appears in the summary

---

### Test 9: `--trend` with no quality log

**Setup:** Ensure `.entropy-patrol/quality-log.jsonl` does not exist.

**Command:** `/entropy-scan --trend`

**Expected output:**
- Message: "No scan history found. Run /entropy-scan a few times to build trend data."
- **No scan is run**

---

### Test 10: `--trend` with sufficient history

**Setup:** Run `/entropy-scan` at least 3 times to populate `.entropy-patrol/quality-log.jsonl`.

**Command:** `/entropy-scan --trend`

**Expected output:**
- Trend summary prints with overall direction, severity breakdown, and per-rule changes
- **No scan is run**
- **No report or log entry written**

---

## entropy-fix Tests

### Test 11: `--dry-run` shows plan without side effects

**Setup:** Run `/entropy-scan` first so `entropy-report.md` exists with at least one `pr_worthy` finding.

**Command:** `/entropy-fix --dry-run`

**Expected output:**
- Preview block prints: how many PRs would be opened, branch names, rule IDs, file lists
- **No branches are created** — `git branch` output is unchanged
- **No files are modified** — repo working tree is clean
- **No PRs are opened** — `gh pr list` is unchanged
- Message confirms: "No branches created. No files changed. No PRs opened."

---

### Test 12: `--rule` flag scopes to a single rule

**Setup:** Ensure `entropy-report.md` has findings for at least two different rules (e.g., `todo_fixme_hack` and `dead_exports`).

**Command:** `/entropy-fix --rule todo_fixme_hack`

**Expected output:**
- Only one PR is opened — for `todo_fixme_hack`
- `dead_exports` findings are untouched
- Branch name follows `fix/entropy-todo_fixme_hack-{description}` pattern
- `entropy-report.md` updated: `todo_fixme_hack` findings checked off, `dead_exports` findings still unchecked

---

### Test 13: Full run on a repo with planted violations

**Setup:**
1. Plant violations for two distinct rules:
   - Add `export function neverUsed() {}` (triggers `dead_exports`)
   - Add `// TODO: remove this` (triggers `todo_fixme_hack`)
2. Run `/entropy-scan` to produce `entropy-report.md`

**Command:** `/entropy-fix`

**Expected output:**
- Two PRs opened (one per rule)
- Each PR title matches the rule description
- Each PR body includes: golden principle reference, file/line list, "Why this matters" section
- Branch names: `fix/entropy-dead_exports-...` and `fix/entropy-todo_fixme_hack-...`
- `entropy-report.md` updated: both finding sets checked off with PR numbers

---

### Test 14: Missing entropy-report.md triggers helpful error

**Setup:** Delete or rename `entropy-report.md` so it doesn't exist in the project root.

**Command:** `/entropy-fix`

**Expected output:**
- Error message: "No entropy-report.md found. Run /entropy-scan first to generate a report."
- Skill exits immediately — no branches created, no PRs opened

---

### Test 15: Confirmation gate for high-severity destructive fix

**Setup:**
1. Add a source file that triggers a high-severity rule involving code deletion (e.g., a file full of dead exports)
2. Run `/entropy-scan` so the high-severity finding is in `entropy-report.md`

**Command:** `/entropy-fix`

**Expected output:**
- Before creating a branch, the skill prints a confirmation prompt listing the affected files and describing the destructive change
- If you respond "no": the group is skipped and noted in the final summary as "no-confirm"
- If you respond "yes": the branch is created, fix applied, PR opened
- Non-destructive rule groups (adding tests, removing unused imports) do NOT trigger the gate

---

### Test 16: No pr_worthy findings

**Setup:** Configure all rules in golden-principles.yaml with `pr_worthy: false`, then run `/entropy-scan` to produce a report with findings.

**Command:** `/entropy-fix`

**Expected output:**
- Message clearly explains: no `pr_worthy` findings to act on
- Lists the reason (all findings are `pr_worthy: false`)
- Suggests running `/entropy-scan` to refresh if needed
- No branches, no PRs

---

## Regression Checks

After any change to `golden-principles.yaml` or `SKILL.md`:

- [ ] Re-run Test 2 (known violation) — findings should still be detected
- [ ] Re-run Test 5 (`--summary`) — no report file should be written
- [ ] Verify `entropy-report.md` format: all findings are `- [ ]` checkboxes
- [ ] Verify security rules run **first** in report output
- [ ] Verify quality log entry appended after a full scan
- [ ] Verify `--summary` does not append to quality log
- [ ] Verify `--trend` produces output with 2+ log entries
