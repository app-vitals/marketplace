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

### Test 9: No golden principles found (broken installation)

**Setup:** Temporarily rename or remove both:
- `.claude/entropy-patrol/golden-principles.yaml` (project config)
- The plugin's default `skills/entropy-scan/golden-principles.yaml`

**Command:** `/entropy-scan`

**Expected output:**
- Message: "No golden principles found. Run `/entropy-scan --init` to get started."
- **No scan is run**
- No `entropy-report.md` is written
- No error or crash

---

## entropy-fix Tests

_(Test plan will be added when EP-4.1 is complete.)_

---

## Regression Checks

After any change to `golden-principles.yaml` or `SKILL.md`:

- [ ] Re-run Test 2 (known violation) — findings should still be detected
- [ ] Re-run Test 5 (`--summary`) — no report file should be written
- [ ] Verify `entropy-report.md` format: all findings are `- [ ]` checkboxes
- [ ] Verify security rules run **first** in report output
