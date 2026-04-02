---
name: audit
description: Daily entropy audit — pull latest, run entropy-scan and entropy-fix against the target repo. Repo path supplied by the caller.
---

# Audit

Run a daily entropy audit against a target repo. Reads the repo's golden principles config, scans for violations, and opens fix PRs for actionable findings.

**Usage:** The caller (cron or human) specifies the repo path and any post-audit steps (e.g. HANDOFF.md updates, notifications).

---

## Step 1: Setup

Parse the repo path from the invocation context (e.g. "run shipwright:audit on ~/path/to/repo" or "audit /path/to/repo").

- `cd <repo-path> && git pull --rebase origin main`
- Confirm `.claude/entropy-patrol/golden-principles.yaml` exists. If not, print:
  ```
  No golden-principles.yaml found at <repo-path>/.claude/entropy-patrol/golden-principles.yaml
  Run /entropy-scan --init to create a starter config, then customize it before running audit again.
  ```
  Then stop.

---

## Step 2: Run entropy-scan

Invoke the `/entropy-scan` skill against the repo. This reads the project's `golden-principles.yaml`, scans for violations, and writes `entropy-report.md`.

---

## Step 3: Run entropy-fix

Invoke the `/entropy-fix` skill. This reads `entropy-report.md` and opens targeted PRs for `pr_worthy` violations — one PR per rule, max 3 files each.

---

## Step 4: Report

Print a summary of what was found and what PRs were opened (or that nothing was actionable). The caller's cron prompt handles any project-specific follow-up (notifications, HANDOFF.md updates, etc.).
