---
name: vitals-os-audit
description: Daily entropy audit of vitals-os — scan for code quality issues, open fix PRs, and update HANDOFF.md.
---

# vitals-os Daily Entropy Audit

Scan vitals-os for code quality issues and open fix PRs autonomously. Designed to run daily; bails gracefully if nothing actionable is found.

---

## 1. Setup

- `cd ~/.bodhi/workspace/vitals-os && git pull --rebase origin main`
- Get recently-modified files (skip in all scans): `git log --since='48 hours ago' --name-only --format='' | sort -u > /tmp/recent-files.txt`
- Check for existing audit PRs today: `gh pr list --search "chore/audit" --state open --json title,headRefName --repo app-vitals/vitals-os` — don't duplicate

---

## 2. Scan (5 categories)

Collect findings for each. Skip files listed in `/tmp/recent-files.txt`.

**Dead exports**: For `{billing,time,cal,agent}/src/*.ts` (not `*.test.ts`), grep for `^export (function|const|class|type|interface|enum)` to get exported symbol names. For each, run `grep -r "<symbol>" --include="*.ts" . | grep -v "<source-file>" | wc -l` — flag symbols with count=0 (zero external imports).

**Missing tests**: For each `{billing,time,cal,agent}/src/*.ts` (not `*.test.ts`, not `index.ts`, not `cli.ts`, not `mcp.ts`), check if a `*.test.ts` exists in the same directory covering that file. Flag files >50 lines (`wc -l`) with no test coverage.

**TODO debt**: `grep -rn "TODO\|FIXME\|HACK" --include="*.ts" {billing,time,cal,agent}/src/ lib/ 2>/dev/null`. Flag only entries where the file's last git touch is >14 days ago: `git log -1 --format="%ar" -- <file>`.

**Swallowed errors**: `grep -rn -A3 "} catch" --include="*.ts" {billing,time,cal,agent}/src/ lib/ 2>/dev/null`. Flag catch blocks whose entire body is empty `{}`, only `console.log/error`, or only `return null/undefined` with no rethrow or error recording.

**Stale planning docs**: Get live remote branches: `git branch -r | grep -o "feat/[^ ]*"`. Check `planning/*.md` — flag docs that reference a `feat/` branch no longer in remote where the work is clearly superseded.

---

## 3. Prioritize (pick top 3 to fix)

Priority order:
1. Dead exports — safe delete, low risk
2. Stale planning docs — safe delete/update
3. Swallowed errors — add `throw err` or `logger.error(err, 'context')`
4. TODO debt — resolve if obvious, skip if complex
5. Missing tests — only if a meaningful test is <30 lines

Don't pick findings that touch recently-modified files. Don't pick if a similar PR already exists today.

---

## 4. Fix and PR (max 3 PRs, max 3 files each)

For each chosen issue:

1. `git checkout -b chore/audit-<category>-$(date +%Y-%m-%d)` (e.g., `chore/audit-dead-export-2026-03-29`)
2. Apply fix — surgical only. If unsure of the right fix, open a descriptive PR stub with no code change.
3. `bun test --passWithNoTests 2>&1 | tail -5` — if tests fail, `git checkout main` and skip this PR
4. `git add -A && git commit -m "[bodhi] chore: <short description>\n\nCo-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"`
5. `git push -u origin <branch>`
6. `gh pr create --title "[bodhi] chore: <description>" --body "## Entropy audit finding\n\n**Category:** <category>\n**Finding:** <what was found>\n**Fix:** <what was changed or why this PR is a stub>\n\nAuto-opened by daily entropy audit (shipwright:vitals-os-audit). Sully: please review.\n\n🤖 Generated with Claude Code" --repo app-vitals/vitals-os`
7. `git checkout main`

---

## 5. HANDOFF.md update

After all PRs:

1. `cd ~/.bodhi/workspace/agent-handoff && git pull --rebase origin main`
2. If PRs opened, append to Transaction Log:
   `[$(date '+%Y-%m-%d %H:%M') PDT] Bodhi: Daily audit. Scanned vitals-os: <N findings> across 5 categories. <M> PRs opened: <list PR links with titles>. Sully: please review.`
3. If no PRs opened, append:
   `[$(date '+%Y-%m-%d %H:%M') PDT] Bodhi: Daily audit. Scanned vitals-os — no actionable issues found.`
4. `git add HANDOFF.md && git commit -m "[bodhi] chore(audit): daily scan $(date +%Y-%m-%d)" && git push`
