---
description: Run a structured planning session that reads input docs, analyzes codebase impact, and produces a stateful task breakdown document
arguments:
  - name: folder-name
    description: Name of the planning session folder under planning/ (e.g., february-2026-workspace-switcher)
    required: true
---

# Planning Session: $ARGUMENTS

Run a structured planning session for the `planning/$ARGUMENTS/` folder. Follow all 9 phases in order — proceed automatically between phases without asking for confirmation. Only pause to ask clarifying questions when information is genuinely ambiguous or missing.

## Phase 0: Setup

### 0a. Check Recommended Plugins

Check if the following plugins are installed by looking for their skills in the available skills list:

| Plugin | Check For | Used In |
|--------|-----------|---------|
| `learning-loop` | `/learn` skill | Phase 7 (Permission pre-flight — adds skill permissions) |
| `frontend-design` | `frontend-design` skill | Phase 4 (Design Skill tagging for UI tasks) |

If any are missing, present:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECOMMENDED PLUGINS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The following plugins enhance the Shipwright pipeline:

MISSING:
  ✗ learning-loop — captures review learnings
    Install: /plugin install learning-loop@app-vitals/marketplace
  ✗ frontend-design — high-quality UI for design-tagged tasks
    Install: /plugin install frontend-design

INSTALLED:
  ✓ {installed plugins}

Continue without them? (Yes / Install first)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If all plugins are installed, skip the prompt and continue. If plugins are missing and the user chooses to continue, note which are unavailable so later phases can skip those features (e.g., omit Design Skill tags in Phase 4 if frontend-design is not installed, skip learning-loop permissions in Phase 7).

### 0b. Detect Project Toolchain

Before starting the planning phases, auto-detect the project's toolchain. This information is used throughout the session.

1. Scan the project root for config files. Check in this order:
   - `package.json` + lockfile (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb`) → Node.js
   - `Cargo.toml` → Rust
   - `go.mod` → Go
   - `pyproject.toml` / `setup.py` / `requirements.txt` → Python
   - `Gemfile` → Ruby
   - `Makefile` → Generic Make

2. For Node.js projects, read `package.json` scripts to identify: `validate`, `build`, `test`, `lint`, `typecheck`/`check`, `format`

3. Check for monorepo indicators: `pnpm-workspace.yaml`, `workspaces` field in `package.json`, `lerna.json`, `nx.json`, `turbo.json`, `go.work`, `[workspace]` in `Cargo.toml`

4. Store detected toolchain for use in later phases:
   - **Ecosystem(s)**: e.g., "Node.js (pnpm)", "Rust (cargo)", "Node.js + Rust"
   - **Package manager**: e.g., pnpm, cargo, go, poetry
   - **Commands**: validate, build, test, lint, typecheck (mapped from detected ecosystem)
   - **Monorepo**: yes/no + workspace tool
   - **Has UI layer**: yes/no (detected from frontend directories, HTML files, or UI framework deps)

5. **E2E Test Detection**: If the project has a UI/frontend layer (detected above or from Phase 3 layer analysis), plan for Playwright end-to-end tests. E2E tests are appropriate when:
   - The project has user-facing UI (web app, browser extension, desktop app with webview)
   - There are interactive elements (forms, toggles, panels, maps, modals)
   - Multiple features interact visually (overlays, dashboards, multi-panel layouts)
   
   If E2E is appropriate, include a dedicated **E2E test feature** in the task breakdown with tasks covering:
   - Playwright setup + smoke tests (page loads, core element renders)
   - Feature interaction tests (toggles, forms, data display)
   - Cross-viewport responsive tests (mobile 375px, tablet 768px, desktop 1440px)
   - Use Playwright route interception for deterministic API mocking
   - Configure screenshot-on-failure for debugging
   
   E2E tests are NOT appropriate for: CLIs, pure backend APIs (use integration tests), libraries, data pipelines without UI.

Refer to `references/toolchain-patterns.md` for the full detection lookup table.

## Phase 1: Session Setup

1. Verify `planning/$ARGUMENTS/` exists and list all files found (PDFs, markdown, images)
2. If the folder does not exist, create it and ask the user to add their input docs before continuing
3. Read all context documents:
   - `CLAUDE.md`
   - `planning/PRODUCT-SPEC.md` (if it exists)
4. Present a summary of inputs to the user:
   - Number and names of docs found in the session folder
   - Confirmation that context docs were loaded
   - Detected toolchain from Phase 0
   - Any missing context docs (warn but continue)
5. Proceed to Phase 2 (no confirmation needed)

## Phase 2: Input Analysis & Requirements Extraction

1. Read each document (PDF, markdown, images) in the planning folder using the Read tool
2. For each document, extract:
   - Features or epics described
   - Specific requirements and acceptance criteria
   - UI mockups or wireframe descriptions
   - Constraints, deadlines, or priorities mentioned
   - Any technical specifications or preferences
3. Categorize requirements into features/epics with clear names
4. Flag any ambiguities, conflicts between docs, or missing information
5. Present a structured requirements summary to the user organized by feature
6. If there are ambiguities or conflicts between docs, ask the user to clarify before proceeding. Otherwise, proceed automatically to Phase 3.

## Phase 3: Codebase Impact Analysis

For each requirement identified in Phase 2:

1. Identify affected code areas in the codebase
2. Check existing modules, components, utilities, and patterns for reuse opportunities
3. Identify what's NEW vs what's a MODIFICATION of existing code
4. **Auto-detect project layers** by scanning the directory structure:
   - `src/api/`, `routes/`, `server/`, `app/api/` → "API"
   - `src/components/`, `pages/`, `frontend/`, `app/`, `src/views/` → "Frontend"
   - `src/db/`, `prisma/`, `migrations/`, `src/models/` → "Database"
   - `src/lib/`, `packages/shared/`, `src/utils/`, `src/common/` → "Shared"
   - `src/workers/`, `src/jobs/`, `src/tasks/`, `src/queue/` → "Background"
   - `src/cli/`, `bin/`, `cmd/` → "CLI"
   - Monorepo packages → one layer per package
   - If auto-detection finds fewer than 2 layers, ask the user to describe their project's architecture layers
5. Map each requirement to its detected layer(s)
6. Note dependencies between features (e.g., "database schema must exist before API can be built")
7. Present the impact analysis and proceed to Phase 4

## Phase 4: Draft Task Breakdown

Generate the combined planning document using the template from `references/planning-doc-template.md`. Write it to:
`planning/$ARGUMENTS/{Project_Name}_Task_Breakdown.md`

### Task ID Convention
- Use a 2-3 letter feature prefix derived from the feature name (e.g., WS for Workspace Switcher, LS for Launch Sets)
- Hierarchical numbering: `PREFIX-N.M` where N is the sub-feature and M is the task number
- Test task IDs use T-suffix: `PREFIX-N.T1`, `PREFIX-N.T2`
- Example: `WS-3.2` means Workspace Switcher, sub-feature 3, task 2

### Estimation Guidelines
- Risk levels: Low, Medium, High
- Every task must have: Description, Technical Details, Acceptance Criteria, Risk, Layer
- Break tasks to 1-8 hour granularity; if a task exceeds 8 hours, split it

### Branch Naming Convention
Branch names are derived from the task ID and title:
- Format: `feat/{task-id-lowered-dots-to-dashes}-{first-3-4-words-kebab}`
- Example: Task `MR-2.1: Extract types + pure-function libs` → `feat/mr-2-1-extract-types-libs`

### Status Values
| Status | Meaning |
|--------|---------|
| `[ ]` | Not started |
| `[🔨]` | In-progress |
| `[x] PR #N` | Done (with PR reference) |
| `[⏸]` | Blocked |
| `[—]` | Skipped |

### Architecture Approach (per task)
Each task gets an architecture approach that determines how implementation proceeds:
- **`minimal`** — Smallest change possible, maximum reuse of existing code. Best for: bug fixes, minor tweaks, wiring tasks.
- **`clean`** — Maintainable abstractions, well-separated concerns. Best for: new modules, foundational scaffolding, shared libraries.
- **`pragmatic`** — Balance of speed and quality. Best for: most feature tasks, UI components, integration work.

Default to `pragmatic` unless the task clearly fits `minimal` or `clean`.

### Design Skill Tagging (Optional)
For tasks on a **Frontend/UI layer** that involve creating or significantly redesigning user-facing components (not minor tweaks or wiring), optionally add:
- `**Design Skill:** {skill-name}` to the task table (e.g., `frontend-design`)

This signals that the implementation workflow should invoke a design skill during implementation for high-quality UI output. Apply this tag when the task involves:
- New pages, panels, or modal UIs
- Significant visual redesigns of existing components
- Onboarding flows, empty states, or first-run experiences
- Any UI where design quality is a differentiator

Do NOT tag tasks that are purely wiring, minor layout adjustments, or non-UI work. Omit the Design Skill row entirely if no design skill is available or applicable.

### Document Structure

Use the full template from `references/planning-doc-template.md`, filling in:
- **Project Metadata**: Use detected toolchain information from Phase 0
- **Layer field**: Use auto-detected layers from Phase 3
- **Coverage Target**: Default 90% (ask user if they want a different threshold)

## Phase 5: Quality Checks

Before presenting the document, verify all of the following. Fix any issues found:

1. **Coverage**: Every input requirement maps to at least one task
2. **Math**: Feature subtotals equal the sum of their individual tasks; grand total equals the sum of all subtotals; executive summary percentages add to 100%
3. **Dependencies**: No circular dependencies; all referenced task IDs exist in the document
4. **Completeness**: Every task has Description, Technical Details, Acceptance Criteria, Risk, Layer, Branch, Context, Architecture, and Implementation Decisions (Edge Cases, Error Handling, Scope Boundaries, Backward Compatibility, Performance)
5. **Granularity**: No single task exceeds 8 hours
6. **Design Skill Tags**: UI-layer tasks that create or significantly redesign user-facing components have a Design Skill tag if applicable; non-UI tasks do not
7. **Appendix**: Complete task list matches the sum of all feature sections
8. **Test Coverage**: Every feature has at least 1 unit test task; multi-module features have at least 1 integration test task. Every test task's AC includes a coverage criterion for the relevant package/flow (using the configured coverage threshold).
9. **E2E Test Coverage**: If the project has a UI/frontend layer, there MUST be a dedicated E2E test feature using Playwright. This feature must include: (a) Playwright setup + smoke tests, (b) feature interaction tests covering all user-facing features, (c) cross-viewport responsive tests at minimum 3 viewport sizes. If no UI layer exists, skip this check.
10. **Status Initialization**: All tasks in appendix and summary tables start with `[ ]`
11. **Branch Uniqueness**: All branch names across all tasks are unique
12. **Context & Branch Fields**: Every task has both Context and Branch fields populated
13. **Implementation Decisions**: Every task has all 5 Implementation Decisions fields filled in (Edge Cases, Error Handling, Scope Boundaries, Backward Compatibility, Performance) — no "TBD" or empty values. These are required for autonomous `/dev-loop` execution.
14. **Architecture Approach**: Every task has an Architecture field set to `minimal`, `clean`, or `pragmatic`

Report the quality check results to the user.

## Phase 6: User Review

1. Present the complete document for review
2. Summarize key metrics: total hours, number of features, number of tasks (implementation + test)
3. Highlight any areas of uncertainty or high risk
4. Iterate on feedback — the user may want to:
   - Adjust estimates
   - Add/remove features
   - Change task granularity
   - Reorder priorities
   - Modify acceptance criteria
5. Update the document with each round of feedback
6. When the user approves, confirm the final document is saved

## Phase 7: Permission Pre-flight

Before `/dev-loop` can run fully autonomously, the project's `.claude/settings.local.json` must allow all Bash commands the pipeline will use. Analyze the project and pre-populate permissions so the user isn't prompted mid-loop.

### 7a. Detect Project Toolchain

Use the toolchain detected in Phase 0. From the codebase analysis in Phase 3 and the project's config files, identify:

1. **Package manager**: from lockfiles or config files
2. **Build/test/lint commands**: from project config (e.g., `package.json` scripts, `Cargo.toml`, `Makefile`)
3. **Language toolchains**: `cargo` (Rust), `go`, `python3`, etc. — from config files or source directories
4. **CI/pipeline commands**: `gh` (GitHub CLI), `git` — always needed
5. **Framework-specific CLIs**: `npx vitest`, `npx eslint`, `npx tsc`, `pytest`, `rspec`, etc.

Refer to `references/toolchain-patterns.md` for the full mapping.

### 7b. Read Existing Permissions

Read `.claude/settings.local.json` (create if missing). Parse the current `permissions.allow` array.

### 7c. Compute Missing Permissions

Build the list of Bash permission patterns the dev pipeline needs. Use broad patterns for trusted dev tools:

| Tool | Pattern | Why |
|------|---------|-----|
| Git | `Bash(git:*)` | All git operations (commit, push, checkout, etc.) |
| GitHub CLI | `Bash(gh:*)` | PR creation, merge, API calls |
| Package manager | `Bash({manager}:*)` | Install, build, test, lint |
| Language tools | `Bash({tool}:*)` | Build, test, lint per ecosystem |
| Shell utilities | `Bash(wc:*)`, `Bash(find:*)`, `Bash(grep:*)` | File analysis |
| Playwright (if E2E) | `Bash(npx playwright:*)` | E2E test execution |
| Planning doc | `Edit(planning/**)` | Status updates during dev-task/dev-loop |
| Planning doc | `Write(planning/**)` | Planning doc creation and updates |

Also include any project-specific commands found in config files.

Compare against existing permissions. Identify what's **missing**.

### 7d. Present & Apply

If there are missing permissions, present them to the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PERMISSION PRE-FLIGHT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The dev pipeline needs these Bash permissions
to run without prompting during /dev-loop:

ALREADY ALLOWED:
  ✓ {existing permissions}

MISSING — will be added:
  + {missing permissions}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask the user: "Add these permissions to `.claude/settings.local.json`? (Yes / Edit list / Skip)"

If approved, update the file and **save a tracking file** so `/dev-loop` can offer to roll back later:

Write `.claude/pipeline-permissions-added.json`:
```json
{
  "added": ["Bash(gh:*)", "Bash(cargo:*)", "..."],
  "addedAt": "{YYYY-MM-DD}",
  "planningDoc": "planning/$ARGUMENTS/{filename}"
}
```

If the settings file doesn't exist, create it with the standard structure:
```json
{
  "permissions": {
    "allow": [
      ...new entries
    ]
  }
}
```

If the settings file exists, merge the new entries into the existing `permissions.allow` array.

Also add skill permissions if optional integrations are detected:
- If `learning-loop` plugin is installed: `Skill(learn)`, `Skill(learning-loop:learn-promote)`
- If `frontend-design` plugin is installed: `Skill(frontend-design)`

---

## Phase 8: Session Summary & Next Steps

Print a session summary showing what was produced:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLANNING SESSION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Document: planning/$ARGUMENTS/{filename}

Tasks: {impl_count} implementation + {test_count} test = {total_count} total
Hours: {total_hours}h estimated
Features: {feature_count}

READY TO START
──────────────
{List all tasks with [ ] status and no dependencies (or all deps [x]):}
- {PREFIX-N.M}: {task title} ({hours}h)

NEXT: /dev-task {first-available-task-id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Important Notes

- Always read the full document content — do not summarize or skip sections
- Reference existing code to identify reuse opportunities rather than proposing to build things from scratch
- When estimating, account for: implementation, testing, edge cases, and integration
- The document should be self-contained — a developer should be able to pick up any task and implement it without additional context
