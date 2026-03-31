# Testing: repo-readiness

Manual test scenarios for `/repo-readiness`. Run against a local repo for each scenario.

---

## Test 1: Unprepared repo (score ~0–20)

**Setup:** Create a temp directory with only a few JS files and no CLAUDE.md, README, or tests.

**Run:** `/repo-readiness`

**Expected:**
- Overall band: "Unprepared" or "Not Ready"
- AC-1 (no CLAUDE.md) flagged as critical
- TC-1 (no test framework) flagged as critical
- Overall cap applied: any critical check failure → band capped at "Not Ready" regardless of other scores
- `readiness-report.md` written with gap list

---

## Test 2: Well-prepared repo (score ~80+)

**Setup:** Use this marketplace repo itself (has CLAUDE.md, README, clear structure, no server so OB-2 skipped).

**Run:** `/repo-readiness`

**Expected:**
- Agent Context: high score (CLAUDE.md exists, layered structure)
- Documentation: high score (README exists)
- No critical gaps
- Band: "Mostly Ready" or "Agent-Ready"
- Report written

---

## Test 3: --fix on unprepared repo

**Setup:** Same empty temp repo as Test 1.

**Run:** `/repo-readiness --fix`

**Expected:**
- CLAUDE.md generated at repo root with inferred architecture section
- If no README.md, README.md created with placeholder sections
- ADR template created at `docs/decisions/ADR-001-template.md`
- Test starter file generated for main entry point (if detected)
- Score (before → after) shows improvement
- Announcement for each generated file

---

## Test 4: --category flag

**Setup:** Any repo.

**Run:** `/repo-readiness --category test_coverage`

**Expected:**
- Only test-coverage checks run
- Report (or stdout) only shows test_coverage category
- No other category results
- `readiness-report.md` written with only TC-* checks

---

## Test 5: --no-report flag

**Setup:** Any repo.

**Run:** `/repo-readiness --no-report`

**Expected:**
- Summary printed to stdout (score + band + category breakdown)
- No `readiness-report.md` written
- Project files unchanged

---

## Test 6: Repo with external doc links

**Setup:** A repo whose CLAUDE.md contains `https://notion.so/...` or `https://confluence.*.com/...` links.

**Run:** `/repo-readiness`

**Expected:**
- AC-4 flagged (external doc links found)
- Number of external links listed in the gap detail
- Suggestion to move content in-repo

---

## Test 7: --fix on repo with oversized CLAUDE.md (AC-3)

**Setup:** A repo with CLAUDE.md over 500 lines.

**Run:** `/repo-readiness --fix`

**Expected:**
- AC-3 flagged with actual line count
- Warning printed: "CLAUDE.md is {N} lines — consider splitting"
- Suggestions printed for which sections to move to subdirectory CLAUDE.md files
- CLAUDE.md itself NOT auto-modified (human-reviewed file)

---

## Test 8: Server app with no health endpoint

**Setup:** A repo with an Express/Hono/FastAPI server but no `/health` route.

**Run:** `/repo-readiness --fix`

**Expected:**
- OB-2 flagged
- Health route added to the server file
- File path + change announced
- Existing routes not disturbed

---

## Test 9: Flat codebase structure (ST-1, ST-2)

**Setup:** Create a repo with 10+ source files all in one flat directory (no src/, lib/, etc.), including one file over 500 lines.

**Run:** `/repo-readiness`

**Expected:**
- ST-1 flagged: no module or layer separation found
- ST-2 flagged: file(s) over 500 lines listed with line counts
- Structure category score is low
- `readiness-report.md` includes both gaps with actionable suggestions

---

## Regression Checklist

Before shipping an update to this plugin:

- [ ] Test 1 runs without crashing on an empty directory
- [ ] Test 3 does not write files if `--fix` is not passed
- [ ] Report format matches `references/scoring.md` spec
- [ ] Critical cap is applied correctly (any critical check failure → band capped at "Not Ready")
- [ ] `--category` limits output to only the named category
- [ ] `--no-report` produces no file writes
