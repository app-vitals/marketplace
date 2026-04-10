# Testing discovery-report

Manual test plan for the `discovery-report` skill. All tests are run by asking Claude Code to invoke the skill with varying inputs, then inspecting the generated HTML file.

---

## Test 1: Fast-path report with skipped interview

**Setup:** Create an empty scratch directory (e.g., `/tmp/discovery-report-test/`) and `cd` into it.

**Prompt:**
> Generate a discovery report for this fabricated incident and skip the interview — here are the facts:
>
> - Service: `checkout-api` in `us-west-2` production
> - Symptom: HTTP 504 on ~8% of requests for 2 hours on 2026-04-07 (14:00–16:00 UTC)
> - Root cause: Redis connection pool leak from PR #4521 (cache call added without releasing the connection on error paths)
> - Fix: `defer client.Close()` wrapped around the Redis call in `internal/cache/redis.go:87`
> - Before: 8% 504 rate, ~40k failed checkouts, 2h duration
> - After: 0% 504 rate after deploy at 16:12 UTC
>
> Write the file to `/tmp/discovery-report-test/`.

**Expected output:**
- A single HTML file at `/tmp/discovery-report-test/<slug>-discovery-report.html`
- File is self-contained — no external `<link>` or `<script>` URLs in `<head>`
- All 8 sections present in the body
- Section 1 (Problem) has a `.callout.red` with a one-sentence problem statement
- Section 4 (Key Metrics) has a `.stats-row` with stat cards AND at least one code block or table showing evidence
- Section 6 (Fix) has a diff-styled code block showing the `defer client.Close()` change
- Section 7 (Before/After) has `.before-after` cards with `.ba-card.before` and `.ba-card.after`, each with ✕/✓ bullets
- Section 8 (Sources & Evidence) table is populated — at minimum with `Verbal: <user>` rows for fabricated claims
- Footer contains "Generated with Claude Code · *discovery-report* skill · Report date: <date>"
- Opening the file in a browser (`open /tmp/discovery-report-test/*.html`) shows the dark theme correctly

---

## Test 2: Full interview mode

**Setup:** Fresh scratch directory.

**Prompt:**
> I want to document an investigation. Run the full discovery-report interview.

**Expected output:**
- Skill asks about Section 1 (problem statement) first
- After Section 1, proceeds through sections 2–7 in order
- During the interview, evidence cues are captured (any mention of numbers, files, commits, queries, Grafana, Confluence, etc.)
- Section 8 is never asked about — skill states it is auto-populated
- Does not proceed to Phase 3 (HTML generation) until sections 1, 3, and 5 have answers
- Final HTML file includes every evidence item mentioned during the interview in the Sources table
- All mandatory components appear (see Test 1 expectations)

---

## Test 3: Update an existing report

**Setup:** Run Test 1 first to produce a baseline HTML file.

**Prompt:**
> Update `checkout-504-discovery-report.html` — add a new finding: the Redis leak was also present in two other services (`orders-api` and `inventory-api`) but masked by their higher timeout tolerances. These need the same `defer` fix.

**Expected output:**
- Skill reads the existing HTML file first (Phase 1: Context Detection)
- Asks what to add or change
- Modifies the relevant sections — likely Section 2 (Pain & Impact) to broaden the blast radius and Section 6 (Fix) to add the additional file paths
- Section 8 (Sources) is updated with any new evidence
- Resulting HTML is still a complete, valid report (no truncation, all sections intact)

---

## Test 4: Report with no investigation journey

**Setup:** Fresh scratch directory.

**Prompt:**
> Generate a discovery report for a simple capacity issue: our `web-frontend` pods hit 85% memory utilization after a traffic spike on 2026-04-08. We bumped the memory limit from 512Mi to 1Gi. No investigation needed — the cause was obvious.

**Expected output:**
- Section 3 (Discovery Journey) is either omitted or uses a brief prose explanation — no timeline required since there were no dead-ends
- Section 7 (Before/After) still shows the memory limit change
- Section 4 still has stat cards (85% utilization, the 512Mi → 1Gi change)
- Section 8 sources table is populated with `Verbal` entries

---

## Test 5: Credential safety

**Setup:** Fresh scratch directory.

**Prompt:**
> Generate a discovery report for a session cookie leak. Root cause: cookie `session_id=abc123xyz789_THIS_IS_A_TEST` was being logged by middleware. Fix: added redaction rule. Use these facts verbatim.

**Expected output:**
- The literal string `abc123xyz789_THIS_IS_A_TEST` does NOT appear in the generated HTML file
- The skill either redacts the value (e.g., `session_id=<redacted>`) or describes the cookie abstractly
- The fact that a cookie was leaked IS documented — just not the value

---

## Test 6: Optional PDF export

**Setup:** Run Test 1 first to produce an HTML report. Ensure `uv --version` works.

**Prompt (after HTML is written):**
> Yes, generate a PDF version as well.

**First-run prerequisite:** If `~/.cache/ms-playwright/` doesn't exist, the skill will run `uv run --with playwright playwright install chromium` and wait for it to finish (~200MB download, 1–2 minutes).

**Expected output:**
- A PDF file next to the HTML file with the same slug and `.pdf` extension
- File size is non-trivial (dark reports with full backgrounds typically land in the 300–800 KB range for an 8-section report across ~6 pages — the background color fills inflate the file vs. a typical text PDF)
- Opening the PDF in Preview.app / Acrobat shows:
  - Dark background (not white) — confirms `print_background=True` worked
  - All 8 sections present in order
  - Stat cards, code blocks, and before/after grids render without layout drift
  - Colors match the HTML version
- The skill reports the absolute path and size

**If chromium is missing:**
- The script exits with a friendly error: "chromium is not installed for playwright. Run this one-time setup command: uv run --with playwright playwright install chromium"
- The script does NOT hang or crash cryptically

**If uv is missing:**
- The skill reports that `uv` is required and points at the install script
- Does not attempt the conversion

---

## Test 7: Confluence upload offer (optional)

**Setup:** Run Test 1, then respond affirmatively when the skill offers a Confluence upload.

**Prompt (after HTML is written):**
> Yes, create a Confluence page. Space key: `ENG`, folder: `Post-Mortems`.

**Expected output:**
- If the Atlassian MCP is available: skill uses `searchConfluenceUsingCql` to find the target, then `createConfluencePage` with `contentFormat: "markdown"`. Returns the page URL.
- If the Atlassian MCP is NOT available: skill reports it cannot upload without Atlassian MCP access and does not error out.

---

## Verification checklist (re-usable)

After any report generation, verify:

- [ ] HTML file exists at the requested location
- [ ] File is self-contained (no external resources)
- [ ] `<head>` contains the full `:root` CSS block (not abbreviated)
- [ ] All 8 sections present in order (unless explicitly skipped)
- [ ] Every section with data has at least one visual component
- [ ] Section 8 table has at least one row per factual claim
- [ ] Footer renders with the skill name and date
- [ ] Dark theme renders correctly when opened in a browser
- [ ] No credentials or session tokens appear anywhere in the file

---

## Regression checks

After any edit to `SKILL.md`, `references/report-structure.md`, or `references/html-template.md`:

- [ ] Re-run Test 1 — full fast-path still produces a valid report
- [ ] Re-run Test 4 — capacity-style reports handle missing discovery journey gracefully
- [ ] Re-run Test 5 — credential redaction is enforced
- [ ] Visually diff the CSS in a generated file against `references/html-template.md` to confirm CSS fidelity
