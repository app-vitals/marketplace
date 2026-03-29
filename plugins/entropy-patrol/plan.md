# Entropy Patrol + Vitals-OS Daily Audit — Task Breakdown

**Prepared:** 2026-03-28
**Based On:** `plan.md` (marketplace roadmap), `plugins/shipwright/plan.md` (harness research), `plugins/damage-control/` (plugin conventions), `plugins/pr-review/` (PR-opening patterns), `~/.bodhi/workspace/crons.json` (Bodhi cron conventions), `~/.bodhi/workspace/src/CLAUDE.md` (Bodhi eng-execute audit — canonical rule source)

> **Important:** The `eng-execute` cron in `~/.bodhi/workspace/src/CLAUDE.md` (Audit section) already runs a subset of these checks on the Bodhi workspace. The default `golden-principles.yaml` **must be seeded from those checks** — not invented independently. Canonical rules from `eng-execute`: missing test coverage (`.test.ts` per source file), ungated outbound HTTP POST/PUT/email/webhook (security/high), TODO/FIXME debt, dead exports, hardcoded secrets, cron integrity (script path + `runTask` usage), recurring log failures. Task EP-2.1 should read `src/CLAUDE.md` Audit section first and map each check to a golden principle rule.

### Project Metadata
| Field | Value |
|-------|-------|
| **Project Type** | Claude Code plugin marketplace (documentation-only repo — markdown, YAML, JSON, Python hooks) |
| **Toolchain** | None (no build/test/lint — markdown-only) |
| **Layers** | Plugin (plugin structure files), Docs (README, TESTING, references), Config (plugin.json, marketplace.json), Cron (Bodhi crons.json) |
| **Coverage Target** | N/A — documentation-only; acceptance criteria are behavioral/structural |

---

## Executive Summary

| Feature | Hours | % of Total |
|---------|-------|------------|
| EP-1: Plugin Scaffold | 1 | 4% |
| EP-2: Golden Principles Config | 2 | 9% |
| EP-3: Entropy Scan Command | 5 | 22% |
| EP-4: Entropy Fix Command | 6 | 26% |
| EP-5: Quality Log | 2 | 9% |
| EP-6: Plugin Registration | 1 | 4% |
| DA-1: Daily Audit Cron Design | 3 | 13% |
| DA-2: Daily Audit Cron Implementation | 3 | 13% |
| **Total** | **23** | 100% |

## Timeline Overview

| Phase | Features | Start | End |
|-------|----------|-------|-----|
| 1 — Foundation | EP-1, EP-2, EP-6 | Day 1 | Day 1 |
| 2 — Core Commands | EP-3, EP-4, EP-5 | Day 2 | Day 3 |
| 3 — Daily Audit Cron | DA-1, DA-2 | Day 4 | Day 5 |

---

## Feature 1: Plugin Scaffold (EP)

### Overview

**Problem:** The `entropy-patrol` plugin doesn't exist yet. We need the standard plugin directory structure that matches the marketplace conventions established by `damage-control`, `learning-loop`, and `pr-review`.

**Solution approach:** Create the full plugin skeleton — `plugin.json`, `README.md`, `TESTING.md`, and stub command/skill files — so subsequent tasks have the right locations to write into.

### 1.1 Plugin Directory and Manifest

#### Task EP-1.1: Create plugin scaffold
| Field | Value |
|-------|-------|
| **ID** | EP-1.1 |
| **Hours** | 1 |
| **Layer** | Plugin, Config |
| **Dependencies** | None |
| **Branch** | `feat/ep-1-1-plugin-scaffold` |
| **Context** | The marketplace uses a consistent plugin structure: `.claude-plugin/plugin.json` for metadata, `commands/` for slash commands, `skills/` for complex workflows, optional `hooks/` for PreToolUse hooks. This task creates that skeleton so all subsequent tasks have the right home. |
| **Architecture** | minimal |

**Description**: Create the full `plugins/entropy-patrol/` directory structure with `plugin.json` manifest stub.

**Technical Details**:
- Location: `plugins/entropy-patrol/`
- Create: `.claude-plugin/plugin.json` with name, version (0.1.0), description, author, keywords, homepage, repository, license — matching the pattern in `damage-control` and `learning-loop`
- Create stub files: `README.md`, `TESTING.md`, `commands/` dir, `skills/` dir
- Keywords: `["quality", "refactoring", "code-health", "entropy", "golden-principles", "automation"]`

**Acceptance Criteria**:
- [ ] `plugins/entropy-patrol/.claude-plugin/plugin.json` exists and is valid JSON with all required fields
- [ ] `plugins/entropy-patrol/README.md` exists (can be placeholder with title and one-liner)
- [ ] `plugins/entropy-patrol/TESTING.md` exists (can be placeholder)
- [ ] `plugins/entropy-patrol/commands/` directory exists
- [ ] `plugins/entropy-patrol/skills/` directory exists

**Risk**: Low

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: Directory may partially exist if tasks are partially done — check before creating
- **Error Handling**: No runtime errors (static files); if directory already exists, update rather than overwrite
- **Scope Boundaries**: Stub only — README.md content written in EP-3.1; TESTING.md content written in EP-4.1
- **Backward Compatibility**: No existing entropy-patrol plugin to preserve
- **Performance**: No special requirements

---

### Feature 1 Test Strategy

No automated tests for markdown/JSON scaffolding — acceptance verified by file existence and JSON validity.

### Feature 1 Summary
| Status | ID | Task | Hours | Layer | Dependencies |
|--------|-----|------|-------|-------|--------------|
| [ ] | EP-1.1 | Create plugin scaffold | 1 | Plugin, Config | None |
| | | **Subtotal** | **1** | | |

---

## Feature 2: Golden Principles Config (EP)

### Overview

**Problem:** `entropy-patrol` needs a configurable rules format — the "golden principles" that define what healthy code looks like in a given repo. Without a clear, editable format, the scanner has nothing to check against and can't be customized per-project.

**Solution approach:** Define a `golden-principles.yaml` schema (modeled on `damage-control`'s `patterns.yaml`) that captures rules by category, severity, and detection hints. Include a default set of universal principles plus a clear customization path for project-specific rules.

### 2.1 Golden Principles Schema and Defaults

#### Task EP-2.1: Define golden principles schema and default ruleset
| Field | Value |
|-------|-------|
| **ID** | EP-2.1 |
| **Hours** | 2 |
| **Layer** | Plugin, Docs |
| **Dependencies** | EP-1.1 |
| **Branch** | `feat/ep-2-1-golden-principles-schema` |
| **Context** | The core value proposition of entropy-patrol is that a team captures their quality norms once, then enforces them continuously. The `golden-principles.yaml` format is the contract between the team's taste and the scanner. It needs to be human-readable, easily customizable, and expressive enough to cover the common categories of drift (dead code, missing tests, inconsistent patterns, etc.). |
| **Architecture** | clean |

**Description**: Create `skills/entropy-scan/golden-principles.yaml` default ruleset and document the schema in `skills/entropy-scan/references/schema.md`.

**Technical Details**:
- Location: `plugins/entropy-patrol/skills/entropy-scan/`
- Create: `golden-principles.yaml` with default rules across these categories:
  - `dead_code` — unused exports, unreferenced files, commented-out blocks
  - `missing_tests` — new files in `src/` without corresponding test files
  - `inconsistent_patterns` — hand-rolled utilities that duplicate shared lib functions
  - `todo_debt` — TODO/FIXME/HACK comments older than the configured age threshold
  - `documentation_gaps` — public functions without docstrings/JSDoc, missing README sections
- Each rule has: `id`, `category`, `severity` (low/medium/high), `description`, `detection_hint` (natural language instruction for the scanning agent), `pr_worthy` (bool — whether this category should trigger a PR in `/entropy-fix`)
- Create: `references/schema.md` documenting the YAML format with examples
- Create: `references/customization.md` explaining how to create project-level overrides (same pattern as damage-control: `.claude/entropy-patrol/golden-principles.yaml` takes priority)

**Acceptance Criteria**:
- [ ] `golden-principles.yaml` exists with at least one rule per category (5+ categories)
- [ ] Each rule has all required fields: `id`, `category`, `severity`, `description`, `detection_hint`, `pr_worthy`
- [ ] `references/schema.md` documents the full YAML schema with a complete example rule
- [ ] `references/customization.md` explains the override path and priority order
- [ ] Schema supports a `disabled: true` field per rule so teams can turn off irrelevant rules without deleting them

**Risk**: Medium — the `detection_hint` field is the key lever for scan quality; hints need to be specific enough that a Claude agent can execute them reliably without being so prescriptive that they're brittle.

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: Rules with `pr_worthy: false` are reported in `/entropy-scan` but skipped during `/entropy-fix` PR creation; ensure this is clear in schema docs
- **Error Handling**: If `golden-principles.yaml` is missing or invalid YAML, the skill should surface a clear error: "No golden principles configured. Run `/entropy-scan` with `--init` to create a starter config, or create `.claude/entropy-patrol/golden-principles.yaml`."
- **Scope Boundaries**: Default rules are intentionally conservative (medium/high severity, PR-worthy only for clear wins). Teams customize for stricter enforcement. Do not include language-specific rules in defaults — only universal patterns.
- **Backward Compatibility**: N/A — new plugin
- **Performance**: No special requirements; YAML file is loaded at skill invocation time

---

### Feature 2 Test Strategy

Testing golden principles schema is behavioral — the schema works if the scan skill can parse it and produce a valid report. Validated as part of EP-3.T1.

### Feature 2 Summary
| Status | ID | Task | Hours | Layer | Dependencies |
|--------|-----|------|-------|-------|--------------|
| [ ] | EP-2.1 | Define golden principles schema and default ruleset | 2 | Plugin, Docs | EP-1.1 |
| | | **Subtotal** | **2** | | |

---

## Feature 3: Entropy Scan Command (EP)

### Overview

**Problem:** Teams need a way to see the current state of codebase health against their golden principles — without any side effects. The scan should be safe to run anytime, producing a report that surfaces drift without opening PRs or modifying code.

**Solution approach:** Build the `/entropy-scan` command as a SKILL.md-driven agent workflow. The skill reads the active `golden-principles.yaml`, instructs the agent to scan the codebase category by category, grades each finding by severity, and produces a structured report. Report format is designed to be human-readable in a terminal/Slack context and machine-readable enough to drive `/entropy-fix`.

### 3.1 Entropy Scan Skill

#### Task EP-3.1: Build entropy-scan skill
| Field | Value |
|-------|-------|
| **ID** | EP-3.1 |
| **Hours** | 3 |
| **Layer** | Plugin |
| **Dependencies** | EP-2.1 |
| **Branch** | `feat/ep-3-1-entropy-scan-skill` |
| **Context** | The scan skill is the core engine of entropy-patrol. It needs to be both actionable (specific findings, not vague) and low-noise (severity grading ensures teams see what matters). The scan should run in ~5–10 minutes on a mid-size codebase and produce a report structured enough that `/entropy-fix` can consume it directly. Pairs with learning-loop: promoted CLAUDE.md patterns can become golden principles. |
| **Architecture** | clean |

**Description**: Write `skills/entropy-scan/SKILL.md` with full scanning workflow instructions, output format spec, and integration with golden principles config.

**Technical Details**:
- Location: `plugins/entropy-patrol/skills/entropy-scan/SKILL.md`
- Skill frontmatter: `name: entropy-scan`, `description: Scan codebase for golden principle deviations. Report only — no code changes.`
- Workflow:
  1. Load active golden principles (check `.claude/entropy-patrol/golden-principles.yaml` first, fall back to plugin default)
  2. For each enabled rule, run the `detection_hint` against the codebase using Read/Glob/Grep tools
  3. Collect findings: file path, line number (if applicable), rule ID, severity, description, estimated fix effort
  4. Group findings by category, sort by severity (high → low)
  5. Write report to `entropy-report.md` in the project root (overwrite on each run)
  6. Print summary to stdout: counts by severity, top 3 findings, suggestion to run `/entropy-fix` for high-severity items
- Report format: markdown sections per category, each finding as a checkbox (so `/entropy-fix` can track resolution), severity badge
- `--init` flag: when passed, copies default `golden-principles.yaml` to `.claude/entropy-patrol/` and exits
- `--summary` flag: print summary only (no full report file write) — useful for cron/CI contexts

**Acceptance Criteria**:
- [ ] `skills/entropy-scan/SKILL.md` exists with complete, unambiguous workflow instructions
- [ ] Skill loads project-level override if present, otherwise falls back to plugin default
- [ ] Output report is written to `entropy-report.md` with findings grouped by category
- [ ] Each finding includes: file path, rule ID, severity, and a one-line description of the issue
- [ ] `--init` flag creates `.claude/entropy-patrol/golden-principles.yaml` with default contents
- [ ] `--summary` flag prints category counts without writing the full report
- [ ] Skill clearly states it makes NO code changes (report only)

**Risk**: Medium — the quality of findings depends heavily on how well the `detection_hint` fields are written. First version will have rough edges; plan for iteration based on real usage.

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: Empty codebase (no src/), golden principles with all rules disabled, scan finding 0 violations (should say "no violations found" not silently succeed)
- **Error Handling**: If golden-principles.yaml is missing and `--init` was not passed, print: "No golden principles found. Run `/entropy-scan --init` to get started." and exit. Don't crash silently.
- **Scope Boundaries**: Report only — no git operations, no PRs, no file modifications. The `entropy-report.md` output file is the only write operation.
- **Backward Compatibility**: N/A — new plugin
- **Performance**: For large repos, scan one category at a time and show progress. Cap scan time with a note if it exceeds 10 minutes.

### 3.2 Entropy Scan Command Stub

#### Task EP-3.2: Create /entropy-scan command stub
| Field | Value |
|-------|-------|
| **ID** | EP-3.2 |
| **Hours** | 1 |
| **Layer** | Plugin |
| **Dependencies** | EP-3.1 |
| **Branch** | `feat/ep-3-2-entropy-scan-command` |
| **Context** | Claude Code slash commands are markdown files with YAML frontmatter. They act as the user-facing entry point that invokes the underlying skill. The command stub is thin — its job is to invoke the entropy-scan skill with the right context. |
| **Architecture** | minimal |

**Description**: Write `commands/entropy-scan.md` slash command that invokes the entropy-scan skill.

**Technical Details**:
- Location: `plugins/entropy-patrol/commands/entropy-scan.md`
- YAML frontmatter: `name: entropy-scan`, `description: Scan codebase for golden principle deviations and generate an entropy report. Flags: --init (create starter config), --summary (print summary only).`
- Body: brief description of what the command does, then "Invoke the entropy-scan skill" — the actual workflow lives in SKILL.md

**Acceptance Criteria**:
- [ ] `commands/entropy-scan.md` exists with valid YAML frontmatter (name, description fields)
- [ ] Command description accurately reflects `--init` and `--summary` flags
- [ ] Command body references the skill rather than duplicating the workflow

**Risk**: Low

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: Command description must not promise things the skill doesn't deliver; keep in sync when skill is updated
- **Error Handling**: All error handling is in the skill; command is pass-through
- **Scope Boundaries**: Command file is documentation/invocation only — no workflow logic here
- **Backward Compatibility**: N/A
- **Performance**: No special requirements

---

### Feature 3 Test Strategy

The entropy-scan skill is tested by running it against the marketplace repo itself (meta: scan for quality issues in a known codebase). Manual test plan covers: scan with no violations, scan with known violations planted, `--init` flag, `--summary` flag.

#### Task EP-3.T1: Write entropy-scan test plan
| Field | Value |
|-------|-------|
| **ID** | EP-3.T1 |
| **Hours** | 1 |
| **Layer** | Docs |
| **Dependencies** | EP-3.1, EP-3.2 |
| **Branch** | `feat/ep-3-t1-scan-test-plan` |
| **Test Type** | integration |
| **Architecture** | minimal |

**Description**: Write `TESTING.md` section for entropy-scan covering manual test scenarios.

**Technical Details**:
- Location: `plugins/entropy-patrol/TESTING.md`
- Scenarios: (1) scan clean repo → expect "no violations"; (2) scan repo with a planted TODO comment → expect it flagged; (3) `--init` flag on repo with no config; (4) `--summary` flag produces summary-only output; (5) project-level golden-principles.yaml overrides plugin default

**Acceptance Criteria**:
- [ ] TESTING.md exists with at least 5 test scenarios for entropy-scan
- [ ] Each scenario includes: setup, command to run, expected output
- [ ] Scenarios cover: clean scan, dirty scan (known violation), --init flag, --summary flag, project override

**Risk**: Low

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: Include a scenario where golden-principles.yaml has a disabled rule to confirm it's skipped
- **Error Handling**: N/A (docs)
- **Scope Boundaries**: Manual test plan only — no automated test framework
- **Backward Compatibility**: N/A
- **Performance**: No special requirements

---

### Feature 3 Summary
| Status | ID | Task | Hours | Layer | Dependencies |
|--------|-----|------|-------|-------|--------------|
| [ ] | EP-3.1 | Build entropy-scan skill | 3 | Plugin | EP-2.1 |
| [ ] | EP-3.2 | Create /entropy-scan command stub | 1 | Plugin | EP-3.1 |
| [ ] | EP-3.T1 | Write entropy-scan test plan (TESTING.md) | 1 | Docs | EP-3.1, EP-3.2 |
| | | **Subtotal** | **5** | | |

---

## Feature 4: Entropy Fix Command (EP)

### Overview

**Problem:** The scan report is useful, but manual remediation at scale doesn't work — that's the whole point. Teams need the scan findings automatically converted into targeted, reviewable PRs: one PR per concern, small blast radius, auto-mergeable when safe.

**Solution approach:** Build `/entropy-fix` as a skill that reads the latest `entropy-report.md`, groups findings by fix type, and for each `pr_worthy` group: opens a branch, makes the targeted fix, and opens a PR with a description explaining what was fixed and why it was a golden principle deviation. Pairs naturally with `pr-review` for the review step.

### 4.1 Entropy Fix Skill

#### Task EP-4.1: Build entropy-fix skill
| Field | Value |
|-------|-------|
| **ID** | EP-4.1 |
| **Hours** | 4 |
| **Layer** | Plugin |
| **Dependencies** | EP-3.1 |
| **Branch** | `feat/ep-4-1-entropy-fix-skill` |
| **Context** | The fix skill is the most complex piece. It needs to: read an existing entropy report, decide which findings are addressable autonomously vs. need human input, make the fixes, and open well-described PRs. The key design principle (from OpenAI's research): one concern per PR, small and reviewable. Don't bundle unrelated fixes. The PR description should explain why the fix aligns with the golden principle — not just what changed. |
| **Architecture** | clean |

**Description**: Write `skills/entropy-fix/SKILL.md` with full fix-and-PR workflow.

**Technical Details**:
- Location: `plugins/entropy-patrol/skills/entropy-fix/SKILL.md`
- Skill frontmatter: `name: entropy-fix`, `description: Read entropy-report.md, fix pr_worthy violations, and open targeted PRs. One PR per concern. Requires entropy-scan to have run first.`
- Workflow:
  1. Check that `entropy-report.md` exists — if not, say "Run /entropy-scan first" and stop
  2. Read the report and filter to `pr_worthy: true` findings that are unchecked (not already fixed)
  3. Group findings by rule ID (one PR per rule, not one PR per file)
  4. For each group, in order of severity (high → low):
     a. Create a branch: `fix/entropy-{rule-id}-{short-description}`
     b. Make the fixes: apply the remediation described in the golden principle's `detection_hint` + context from the finding
     c. Commit with message: `fix(entropy): resolve {rule.id} — {finding count} instances`
     d. Open PR using `gh pr create` with structured body (see PR body format below)
     e. Update `entropy-report.md` — check off fixed findings
  5. After all PRs: print summary of PRs opened with links
- PR body format:
  ```
  ## Entropy Fix: {rule.description}

  **Golden Principle:** {rule.id} ({rule.severity})
  **Findings fixed:** {count}

  ### What was changed
  {bullet list of files/changes}

  ### Why this matters
  {rule.description — explain the principle being enforced}

  ### Review notes
  {any caveats — e.g., "3 instances were auto-fixed; 2 flagged as needs-human-review"}
  ```
- `--dry-run` flag: print what PRs would be opened without actually creating branches or PRs
- `--rule {id}` flag: fix only violations of a specific rule
- Human-in-the-loop gate: if a finding has `severity: high` AND the fix involves deleting code (not just moving or adding), print a summary and ask for confirmation before proceeding

**Acceptance Criteria**:
- [ ] `skills/entropy-fix/SKILL.md` exists with complete workflow
- [ ] Skill checks for `entropy-report.md` existence before proceeding
- [ ] PRs are one-per-rule, not one-per-file
- [ ] Branch naming follows `fix/entropy-{rule-id}-{short-description}` pattern
- [ ] PR body includes: golden principle reference, change summary, why it matters
- [ ] `--dry-run` flag prints plan without side effects
- [ ] `--rule` flag scopes fix to a single rule ID
- [ ] High-severity delete operations require explicit confirmation before executing

**Risk**: High — making automated code changes and opening PRs is inherently high-stakes. The human-in-the-loop gate for destructive operations is critical. The skill must be clear that PRs need human review before merge (never auto-merge without explicit configuration).

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: No `entropy-report.md` (prompt to run scan first); report has no `pr_worthy` findings (say so clearly); fixing one finding uncovers another (scope to the original report only, don't cascade); branch already exists (skip with note)
- **Error Handling**: `gh pr create` failures should be reported per-PR, not abort the whole run. Log failures and continue to next group. At the end, report: "3/5 PRs opened successfully. 2 failed: [details]"
- **Scope Boundaries**: Fixes only the findings listed in `entropy-report.md` at the time the skill runs. Does not re-scan. Does not merge PRs. Does not run tests. Does not modify golden-principles.yaml.
- **Backward Compatibility**: N/A — new plugin
- **Performance**: Open PRs sequentially, not in parallel — parallel branch creation causes git conflicts. Cap at 10 PRs per run; if more findings, note "10 PRs opened; re-run to continue."

### 4.2 Entropy Fix Command Stub

#### Task EP-4.2: Create /entropy-fix command stub
| Field | Value |
|-------|-------|
| **ID** | EP-4.2 |
| **Hours** | 1 |
| **Layer** | Plugin |
| **Dependencies** | EP-4.1 |
| **Branch** | `feat/ep-4-2-entropy-fix-command` |
| **Context** | Thin command wrapper that invokes the entropy-fix skill. Same pattern as /entropy-scan command. |
| **Architecture** | minimal |

**Description**: Write `commands/entropy-fix.md` slash command that invokes entropy-fix skill.

**Technical Details**:
- Location: `plugins/entropy-patrol/commands/entropy-fix.md`
- YAML frontmatter: `name: entropy-fix`, `description: Read entropy-report.md and open targeted refactoring PRs for pr_worthy violations. One PR per golden principle. Flags: --dry-run (preview), --rule {id} (fix one rule).`

**Acceptance Criteria**:
- [ ] `commands/entropy-fix.md` exists with valid YAML frontmatter
- [ ] Description mentions `--dry-run` and `--rule` flags
- [ ] Description clearly states that `/entropy-scan` must be run first

**Risk**: Low

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: Keep description in sync with skill flags
- **Error Handling**: All handling in skill
- **Scope Boundaries**: Command file is invocation only
- **Backward Compatibility**: N/A
- **Performance**: No special requirements

---

### Feature 4 Test Strategy

Test plan covers: dry-run mode, single rule fix, full run, confirmation gate for high-severity deletes.

#### Task EP-4.T1: Write entropy-fix test plan
| Field | Value |
|-------|-------|
| **ID** | EP-4.T1 |
| **Hours** | 1 |
| **Layer** | Docs |
| **Dependencies** | EP-4.1, EP-4.2 |
| **Branch** | `feat/ep-4-t1-fix-test-plan` |
| **Test Type** | integration |
| **Architecture** | minimal |

**Description**: Add entropy-fix test scenarios to `TESTING.md`.

**Technical Details**:
- Location: `plugins/entropy-patrol/TESTING.md`
- Scenarios: (1) `--dry-run` shows plan without creating branches; (2) `--rule` scopes to one rule; (3) full run on a repo with planted violations creates one PR per rule; (4) missing entropy-report.md triggers helpful error; (5) confirmation gate fires for high-severity destructive fix

**Acceptance Criteria**:
- [ ] TESTING.md updated with at least 5 entropy-fix scenarios
- [ ] `--dry-run` scenario confirms no branches/PRs created
- [ ] Confirmation gate scenario is explicitly tested

**Risk**: Low

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: Test case for "no pr_worthy findings" should be included
- **Error Handling**: N/A (docs)
- **Scope Boundaries**: Manual test plan only
- **Backward Compatibility**: N/A
- **Performance**: No special requirements

---

### Feature 4 Summary
| Status | ID | Task | Hours | Layer | Dependencies |
|--------|-----|------|-------|-------|--------------|
| [ ] | EP-4.1 | Build entropy-fix skill | 4 | Plugin | EP-3.1 |
| [ ] | EP-4.2 | Create /entropy-fix command stub | 1 | Plugin | EP-4.1 |
| [ ] | EP-4.T1 | Write entropy-fix test plan (TESTING.md) | 1 | Docs | EP-4.1, EP-4.2 |
| | | **Subtotal** | **6** | | |

---

## Feature 5: Quality Log (EP)

### Overview

**Problem:** Without tracking drift over time, teams can't tell if `entropy-patrol` is actually working. A one-off scan is a snapshot; a quality log is a trend. Teams need to see whether violations are accumulating or decreasing sprint-over-sprint.

**Solution approach:** Define a lightweight `quality-log.jsonl` format (append-only, one line per scan run) that captures: timestamp, total violations by severity, counts per rule. A skill reads this log and produces a trend summary. The log is committed to the repo so it's visible in git history.

### 5.1 Quality Log Format and Tracking

#### Task EP-5.1: Define quality log format and write to it from entropy-scan
| Field | Value |
|-------|-------|
| **ID** | EP-5.1 |
| **Hours** | 1 |
| **Layer** | Plugin, Docs |
| **Dependencies** | EP-3.1 |
| **Branch** | `feat/ep-5-1-quality-log-format` |
| **Context** | The quality log is the mechanism that makes entropy-patrol a continuous practice rather than a one-time audit. JSONL (one JSON object per line) is append-only and git-diff-friendly — easy to see what changed between runs. The log lives in `.entropy-patrol/quality-log.jsonl` by convention (gitignored or committed, per team preference). |
| **Architecture** | clean |

**Description**: Define `quality-log.jsonl` schema and update entropy-scan skill to append a log entry after each scan.

**Technical Details**:
- Location: `plugins/entropy-patrol/skills/entropy-scan/references/quality-log-schema.md`
- Log entry schema:
  ```json
  {
    "timestamp": "ISO-8601",
    "commitSha": "short git sha at time of scan",
    "totalViolations": 12,
    "bySeverity": {"high": 2, "medium": 6, "low": 4},
    "byRule": {"dead_code_exports": 3, "todo_debt": 5, "missing_tests": 4},
    "reportPath": "entropy-report.md"
  }
  ```
- Update `skills/entropy-scan/SKILL.md` to: after writing `entropy-report.md`, append a log entry to `.entropy-patrol/quality-log.jsonl` (create directory/file if needed)
- Document: the log file should be committed to the repo (not gitignored) so trend data is preserved in git history

**Acceptance Criteria**:
- [ ] `references/quality-log-schema.md` documents the JSONL schema with a complete example entry
- [ ] entropy-scan skill updated to append log entry after each scan
- [ ] Log entry includes: timestamp, commitSha, totalViolations, bySeverity, byRule
- [ ] Skill creates `.entropy-patrol/` directory if it doesn't exist
- [ ] Recommendation to commit log file is documented

**Risk**: Low

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: Log file corrupted (one malformed line) — reads should skip malformed lines gracefully; appends always succeed since append is atomic
- **Error Handling**: If git is not available (non-git directory), omit `commitSha` from log entry rather than failing
- **Scope Boundaries**: Log is append-only — never rewrite or truncate. Trend analysis is a read operation only.
- **Backward Compatibility**: N/A
- **Performance**: JSONL is append-only so log never needs to be fully loaded; trend queries read only the last N lines

### 5.2 Quality Trend Summary

#### Task EP-5.2: Write quality log reading and trend skill
| Field | Value |
|-------|-------|
| **ID** | EP-5.2 |
| **Hours** | 1 |
| **Layer** | Plugin |
| **Dependencies** | EP-5.1 |
| **Branch** | `feat/ep-5-2-quality-trend-skill` |
| **Context** | A companion view to the scan report: instead of "what's wrong now?", it answers "is the codebase getting better or worse?". This view is especially useful for the daily audit cron (DA workstream) where Sully can look at the log to see if his review work is reducing violations. |
| **Architecture** | minimal |

**Description**: Add `--trend` flag to entropy-scan skill that reads quality-log.jsonl and prints a trend summary.

**Technical Details**:
- Update `skills/entropy-scan/SKILL.md` to handle `--trend` flag:
  - Read `.entropy-patrol/quality-log.jsonl` (last 30 entries or configurable)
  - Print: total violations over time (delta from first to last entry), per-rule trends (improving/worsening/stable), most improved rule, most worsening rule
  - Format: simple text table, no charts (CLI-friendly)
- If log has < 2 entries: "Not enough scan history for trends. Run /entropy-scan a few times to build history."

**Acceptance Criteria**:
- [ ] `--trend` flag documented in `skills/entropy-scan/SKILL.md`
- [ ] Trend output shows: overall delta, per-rule direction, most improved and most worsening
- [ ] Handles insufficient history gracefully with a helpful message
- [ ] Trend reads at most 30 entries (configurable via `--window N`)

**Risk**: Low

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: Log file doesn't exist yet, log has exactly 1 entry, all rules have identical counts across runs
- **Error Handling**: Missing log file → "No scan history found. Run /entropy-scan first."
- **Scope Boundaries**: Read only — no writes. Does not trigger a new scan.
- **Backward Compatibility**: N/A
- **Performance**: Read last 30 lines only; don't load entire log for large repos

---

### Feature 5 Test Strategy

Test plan covers: first log entry written, trend output with 2+ entries, insufficient history message.

### Feature 5 Summary
| Status | ID | Task | Hours | Layer | Dependencies |
|--------|-----|------|-------|-------|--------------|
| [ ] | EP-5.1 | Quality log format and scan integration | 1 | Plugin, Docs | EP-3.1 |
| [ ] | EP-5.2 | Quality trend flag | 1 | Plugin | EP-5.1 |
| | | **Subtotal** | **2** | | |

---

## Feature 6: Plugin Registration (EP)

### Overview

**Problem:** The new plugin needs to be registered in the marketplace manifest so it's discoverable via `/plugin install`.

**Solution approach:** Add entropy-patrol to `marketplace.json` and write the full README.md with installation instructions, command reference, and the integration story with damage-control and learning-loop.

### 6.1 Marketplace Registration and README

#### Task EP-6.1: Register plugin and write README
| Field | Value |
|-------|-------|
| **ID** | EP-6.1 |
| **Hours** | 1 |
| **Layer** | Config, Docs |
| **Dependencies** | EP-4.2, EP-5.2 |
| **Branch** | `feat/ep-6-1-register-and-readme` |
| **Context** | The marketplace.json manifest is what makes the plugin discoverable. The README is what convinces a team to install it — it needs to clearly explain the problem it solves, the workflow, and how it fits with the other plugins (damage-control prevents new drift, entropy-patrol fixes existing drift, learning-loop promotes patterns to golden principles). |
| **Architecture** | minimal |

**Description**: Add entropy-patrol to `.claude-plugin/marketplace.json` and write the full `plugins/entropy-patrol/README.md`.

**Technical Details**:
- Update `.claude-plugin/marketplace.json`: add entry with name, description, source path — matching existing plugin entries
- Write `plugins/entropy-patrol/README.md` covering:
  - Problem statement (the OpenAI "Friday cleanup" insight)
  - Quick start (install → `--init` → first scan → first fix)
  - Command reference: `/entropy-scan`, `/entropy-fix` with all flags
  - Golden principles config: schema overview, customization path
  - Quality log: how to read trends
  - Integration with damage-control (prevention) and learning-loop (promotion)
  - How it fits into a recurring practice (weekly scan + fix cycle)

**Acceptance Criteria**:
- [ ] `marketplace.json` updated with entropy-patrol entry (valid JSON, all required fields)
- [ ] `README.md` covers: problem, quick start, both commands with flags, config customization, quality log, plugin integrations
- [ ] Quick start shows a realistic 3-step workflow from install to first PR
- [ ] Marketplace.json version field is bumped for the root entry

**Risk**: Low

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: marketplace.json version bump — bump patch version (e.g., 2.0.0 → 2.1.0) to reflect new plugin addition
- **Error Handling**: N/A (docs/config)
- **Scope Boundaries**: README is about entropy-patrol only; ecosystem integrations are brief references, not full documentation
- **Backward Compatibility**: Existing marketplace.json entries must be preserved exactly
- **Performance**: No special requirements

---

### Feature 6 Summary
| Status | ID | Task | Hours | Layer | Dependencies |
|--------|-----|------|-------|-------|--------------|
| [ ] | EP-6.1 | Register plugin and write README | 1 | Config, Docs | EP-4.2, EP-5.2 |
| | | **Subtotal** | **1** | | |

---

## Feature 7: Daily Audit Cron Design (DA)

### Overview

**Problem:** The entropy-patrol plugin is a human-triggered tool. But Bodhi runs on a schedule — crons in `~/.bodhi/workspace/crons.json`. The opportunity is to have Bodhi autonomously audit the `vitals-os` repo daily, opening PRs when it spots issues, without anyone having to remember to trigger it. This is separate from entropy-patrol (it uses Bodhi's Bash/Git tools directly, not the plugin) and complements it (different angle: "morning code review" vs. "golden principle enforcement").

**Solution approach:** Design a Bodhi cron job that: pulls vitals-os, runs a structured code quality scan using Claude's own tools (no external scanner required), and opens targeted PRs for clear wins. Sully reviews. The cron prompt is the key artifact — it needs to be specific enough that Bodhi produces high-quality, low-noise findings.

### 7.1 Daily Audit Cron Design

#### Task DA-1.1: Design the daily audit cron prompt and PR workflow
| Field | Value |
|-------|-------|
| **ID** | DA-1.1 |
| **Hours** | 3 |
| **Layer** | Docs |
| **Dependencies** | None |
| **Branch** | `feat/da-1-1-audit-cron-design` |
| **Context** | This is the design doc for the cron work. The implementation (writing to crons.json) is DA-2.1. The design needs to nail three things: (1) what categories to check (specific enough to produce actionable findings, not a vague "check for quality issues"), (2) how to avoid noise (low-noise means fewer, higher-confidence findings), (3) the PR workflow (how Bodhi opens a PR in vitals-os without polluting the review queue with low-quality changes). The Bodhi cron system is documented in ~/.bodhi/workspace/crons.json — prompts run via Claude Code with full shell access. |
| **Architecture** | clean |

**Description**: Write a design document for the vitals-os daily audit cron, capturing: scan categories, noise filters, PR workflow, Sully review handoff.

**Technical Details**:
- Location: `plugins/entropy-patrol/references/daily-audit-cron-design.md`
- Contents:

  **Scan Categories (what Bodhi checks):**
  1. **Dead code** — exported functions/types with no import references across the codebase
  2. **Missing tests** — files in `src/` that have no corresponding `*.test.ts` or `*.spec.ts`
  3. **TODO/FIXME debt** — TODO and FIXME comments (log them, open a PR only if they've been there for >7 days based on `git log -p`)
  4. **Inconsistent error handling** — async functions that catch errors but swallow them (empty catch blocks or `catch (e) {}`)
  5. **Stale documentation** — README sections that reference files/commands that no longer exist

  **Noise Filters:**
  - Skip findings if blast radius > 3 files (too risky for autonomous fix)
  - Skip findings if the file was modified in the last 48 hours (may be work-in-progress)
  - Skip findings in `node_modules/`, `dist/`, `*.d.ts` files
  - Cap at 3 PRs per daily run — focus on highest-confidence findings
  - If no high-confidence findings: `[silent]` — don't post noise

  **PR Workflow:**
  - Bodhi uses `gh pr create` targeting `app-vitals/vitals-os` (requires GH_TOKEN with write access to that repo)
  - Branch naming: `bodhi/audit-{date}-{category}` (e.g., `bodhi/audit-2026-03-28-dead-code`)
  - PR title: `[Bodhi Audit] {category}: {short description}`
  - PR body: what was found, why it's a problem, what was changed, confidence level
  - PR is tagged with `audit` label and assigned to Sully for review

  **Sully Review Handoff:**
  - After PRs are opened, Bodhi writes a summary to `agent-handoff/HANDOFF.md` under "Handoff Queue" — "Sully: review {N} audit PRs in vitals-os"
  - Sully picks this up on his next agent-handoff-check cycle

  **State File:**
  - Maintain `~/.bodhi/workspace/state/last-audit.json` with `{"lastRun": "ISO timestamp", "prCount": N, "findings": [...]}`
  - `eng-execute` cron already reads this pattern; audit cron follows same convention

**Acceptance Criteria**:
- [ ] `references/daily-audit-cron-design.md` exists with all sections: scan categories, noise filters, PR workflow, Sully handoff, state file
- [ ] Each scan category has: what it looks for, how to detect it, what fix looks like
- [ ] Noise filters section explains the rationale for each filter
- [ ] PR workflow covers: branch naming, title format, body format, label/assignee
- [ ] Design notes the GH_TOKEN requirement (Bodhi needs write access to vitals-os)
- [ ] State file format documented so implementation can follow it

**Risk**: Medium — the PR-opening workflow requires Bodhi to have write access to a repo it doesn't currently own. GH_TOKEN scoping needs to be confirmed before implementation.

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: vitals-os repo not cloned locally (cron needs to clone/pull first); no findings (must use [silent] not an empty post); rate limiting on GitHub API (cap at 3 PRs/day)
- **Error Handling**: If `gh pr create` fails (e.g., branch already exists), log to `state/last-audit.json` under a `failures` array and post a note to Dan — don't silently swallow
- **Scope Boundaries**: Design doc only — no crons.json changes in this task (that's DA-2.1)
- **Backward Compatibility**: Must not break existing eng-execute state file conventions
- **Performance**: Audit should complete within 10 minutes; if it's running longer, cap with a note

---

### Feature 7 Summary
| Status | ID | Task | Hours | Layer | Dependencies |
|--------|-----|------|-------|-------|--------------|
| [ ] | DA-1.1 | Design daily audit cron prompt and PR workflow | 3 | Docs | None |
| | | **Subtotal** | **3** | | |

---

## Feature 8: Daily Audit Cron Implementation (DA)

### Overview

**Problem:** The design doc from DA-1.1 needs to be turned into an actual cron entry in `~/.bodhi/workspace/crons.json` — a carefully crafted prompt that Bodhi can execute reliably every morning.

**Solution approach:** Write the cron prompt using the patterns established by existing Bodhi crons (see `eng-execute` and `daily-cleanup` for the style). The prompt is the implementation — it needs to be specific, include all the steps, and handle edge cases inline (since Claude doesn't have a separate "code" file to fall back to).

### 8.1 Cron Entry

#### Task DA-2.1: Write the vitals-os daily audit cron entry
| Field | Value |
|-------|-------|
| **ID** | DA-2.1 |
| **Hours** | 2 |
| **Layer** | Cron |
| **Dependencies** | DA-1.1 |
| **Branch** | `feat/da-2-1-audit-cron-entry` |
| **Context** | Bodhi crons are defined in ~/.bodhi/workspace/crons.json. Each cron has an id, schedule (cron syntax), prompt (the full instruction set for Claude), and user/channel routing. The prompt is effectively the code — it must be self-contained and handle all edge cases inline. The `eng-execute` cron (runs at :10 past every hour) is the best reference: it reads state, does work, reports only on exceptions. The audit cron should follow the same pattern: do the work silently, report only when there's something actionable (a PR was opened or something went wrong). |
| **Architecture** | pragmatic |

**Description**: Add `vitals-os-audit` cron entry to `~/.bodhi/workspace/crons.json` with a complete, battle-tested prompt.

**Technical Details**:
- File: `~/.bodhi/workspace/crons.json`
- New entry:
  ```json
  {
    "id": "vitals-os-audit",
    "schedule": "0 7 * * 1-5",
    "prompt": "...(see below)...",
    "user": "U0AALR8M69X",
    "enabled": true
  }
  ```
- Schedule: 7:00 AM Pacific, Monday–Friday (after morning brief, before check-hours-today)
- Prompt structure (to be written in full):
  1. **Pull vitals-os**: `cd ~/.bodhi/workspace/vitals-os && git pull --rebase origin main` (fail fast if this errors)
  2. **Read state**: `~/.bodhi/workspace/state/last-audit.json` — skip if last run was < 20 hours ago (prevents double-run)
  3. **Run scan** by category (as defined in DA-1.1):
     - Dead code scan using Grep + cross-reference
     - Missing test scan using Glob to find `src/**/*.ts` without matching `*.test.ts`
     - TODO debt scan using Grep + git log to age the comments
     - Swallowed error scan using Grep for empty catch blocks
     - (Skip stale docs for v1 — too noisy)
  4. **Apply noise filters** (< 48h modified, < 3-file blast radius, skip dist/node_modules)
  5. **For each high-confidence finding** (up to 3):
     - Checkout branch `bodhi/audit-{date}-{category}`
     - Make the fix
     - Commit with `fix(audit): {description}`
     - `gh pr create` with structured body, `--label audit`, `--reviewer sully` (or Sully's GitHub handle)
  6. **Update state file**: write `last-audit.json` with run timestamp and PR count
  7. **Update agent-handoff**: if PRs were opened, append to HANDOFF.md handoff queue
  8. **Report**: if PRs opened → summarize them; if nothing found → `[silent]`

**Acceptance Criteria**:
- [ ] `crons.json` updated with `vitals-os-audit` entry (valid JSON)
- [ ] Schedule is `0 7 * * 1-5` (weekdays at 7am)
- [ ] Prompt includes all 8 steps described above
- [ ] Prompt handles the "< 20 hours since last run" guard
- [ ] Prompt handles the "no findings" case with `[silent]`
- [ ] Prompt handles `git pull` failure (report error to Dan, don't proceed)
- [ ] Prompt caps at 3 PRs per run

**Risk**: High — this cron opens PRs in a shared repo autonomously. The noise filters and PR cap are critical safety mechanisms. Pre-flight requirement: confirm GH_TOKEN has write access to `app-vitals/vitals-os` before enabling.

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: vitals-os not cloned locally (prompt should detect and instruct Dan to clone it first, then disable itself with a note); GH_TOKEN lacks write access (gh pr create will fail — catch and report); last-audit.json doesn't exist yet (treat as never run)
- **Error Handling**: Any step failure → log to last-audit.json under `lastError`, post to Dan with context, use `[silent]` only for clean no-findings runs (never for errors)
- **Scope Boundaries**: Only scans vitals-os — not other repos. Does not merge PRs. Does not run tests. Does not modify crons.json entries for other crons.
- **Backward Compatibility**: Appending to crons.json — must preserve all existing entries exactly. Validate JSON after writing.
- **Performance**: Total cron run time should be under 10 minutes. If scan is taking longer, truncate at 5 categories and note in report.

### 8.2 GH Token and Permissions Pre-flight

#### Task DA-2.2: Document GH_TOKEN requirements and pre-flight steps
| Field | Value |
|-------|-------|
| **ID** | DA-2.2 |
| **Hours** | 1 |
| **Layer** | Docs |
| **Dependencies** | DA-2.1 |
| **Branch** | `feat/da-2-2-gh-token-preflight` |
| **Context** | The audit cron opens PRs in app-vitals/vitals-os. Bodhi's GH_TOKEN (in ~/.bodhi/.env) may or may not have write access to that repo. Before the cron is enabled, this needs to be checked. This task produces a short pre-flight checklist that Dan runs once before enabling the cron. |
| **Architecture** | minimal |

**Description**: Write a pre-flight checklist for enabling the vitals-os-audit cron, covering GH_TOKEN scoping, vitals-os local clone, and Sully's reviewer assignment.

**Technical Details**:
- Location: `plugins/entropy-patrol/references/daily-audit-preflight.md`
- Checklist:
  1. Verify `gh auth status` shows the correct account
  2. Verify write access: `gh repo view app-vitals/vitals-os` should succeed
  3. Clone vitals-os locally: `git clone git@github.com:app-vitals/vitals-os.git ~/.bodhi/workspace/vitals-os`
  4. Add vitals-os to `.gitignore` in workspace (it's a separate git repo)
  5. Add vitals-os to `sync-repos.ts` so it stays up to date
  6. Set `"enabled": true` in the cron entry
  7. Run a dry-run: manually trigger the cron prompt and verify `[silent]` output (no findings expected in a fresh repo)

**Acceptance Criteria**:
- [ ] `references/daily-audit-preflight.md` exists with the 7-step checklist
- [ ] Each step includes the exact command to run
- [ ] Checklist notes that `enabled: false` should stay until all steps complete
- [ ] Document notes the consequence of GH_TOKEN lacking write access (silent failure mode)

**Risk**: Low

**Implementation Decisions** (pre-answers for autonomous development):
- **Edge Cases**: Sully's GitHub handle needs to be confirmed (use as `--reviewer` in `gh pr create`)
- **Error Handling**: N/A (docs)
- **Scope Boundaries**: Pre-flight only; does not modify any code files
- **Backward Compatibility**: N/A
- **Performance**: No special requirements

---

### Feature 8 Test Strategy

The cron is tested by manual dry-run before enabling. Test plan: trigger the cron prompt manually in a Claude Code session pointed at vitals-os, verify it produces valid output (either PRs or [silent]), check state file is written.

### Feature 8 Summary
| Status | ID | Task | Hours | Layer | Dependencies |
|--------|-----|------|-------|-------|--------------|
| [ ] | DA-2.1 | Write vitals-os-audit cron entry | 2 | Cron | DA-1.1 |
| [ ] | DA-2.2 | GH token and permissions pre-flight doc | 1 | Docs | DA-2.1 |
| | | **Subtotal** | **3** | | |

---

## Assumptions & Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| entropy-fix making bad automated code changes | High — corrupts codebase or generates noise PRs | `--dry-run` default for first use; human-in-the-loop gate for high-severity destructive changes; PR cap of 10 |
| Daily audit cron GH_TOKEN lacking write access to vitals-os | High — cron silently fails | DA-2.2 pre-flight checklist; cron reports `gh pr create` failures to Dan |
| Golden principle detection_hints being too vague | Medium — scan produces low-quality findings | Default ruleset is conservative; teams iterate detection_hints based on actual results; learning-loop promotion path refines rules over time |
| Daily audit cron generating noise for Sully | Medium — review queue gets polluted | 3-PR daily cap; noise filters (48h recency, 3-file blast radius); high-confidence findings only |
| vitals-os not cloned locally when cron runs | Medium — cron errors on first run | DA-2.2 pre-flight checklist; cron prompt detects missing clone and reports to Dan |

## Out of Scope

- Automated merging of entropy-fix PRs (always human-reviewed)
- Language-specific default golden principles (teams add these via project overrides)
- CI/CD integration for entropy-scan (out of scope for v1 — intended as a Claude Code tool)
- Sully writing a parallel audit cron (deferred — Bodhi's cron is the proof-of-concept; if useful, Sully's team can add one)
- Multi-repo entropy tracking (quality-dashboard plugin is the right home for this — see marketplace roadmap)
- Stale documentation scan in daily audit v1 (too noisy; consider after noise filter calibration)

---

## Appendix: Complete Task List

| Status | ID | Task | Hours | Layer | Dependencies |
|--------|-----|------|-------|-------|--------------|
| [ ] | EP-1.1 | Create plugin scaffold | 1 | Plugin, Config | None |
| [ ] | EP-2.1 | Define golden principles schema and default ruleset | 2 | Plugin, Docs | EP-1.1 |
| [ ] | EP-3.1 | Build entropy-scan skill | 3 | Plugin | EP-2.1 |
| [ ] | EP-3.2 | Create /entropy-scan command stub | 1 | Plugin | EP-3.1 |
| [ ] | EP-3.T1 | Write entropy-scan test plan | 1 | Docs | EP-3.1, EP-3.2 |
| [ ] | EP-4.1 | Build entropy-fix skill | 4 | Plugin | EP-3.1 |
| [ ] | EP-4.2 | Create /entropy-fix command stub | 1 | Plugin | EP-4.1 |
| [ ] | EP-4.T1 | Write entropy-fix test plan | 1 | Docs | EP-4.1, EP-4.2 |
| [ ] | EP-5.1 | Quality log format and scan integration | 1 | Plugin, Docs | EP-3.1 |
| [ ] | EP-5.2 | Quality trend flag | 1 | Plugin | EP-5.1 |
| [ ] | EP-6.1 | Register plugin and write README | 1 | Config, Docs | EP-4.2, EP-5.2 |
| [ ] | DA-1.1 | Design daily audit cron prompt and PR workflow | 3 | Docs | None |
| [ ] | DA-2.1 | Write vitals-os-audit cron entry | 2 | Cron | DA-1.1 |
| [ ] | DA-2.2 | GH token and permissions pre-flight doc | 1 | Docs | DA-2.1 |
| | | **Total** | **23** | | |
