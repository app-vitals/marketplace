---
description: Analyze codebase and generate or update project documentation
argument-hint: "[module-or-topic]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Research Docs

Analyze the codebase, audit existing documentation, identify gaps and stale content, then generate or update docs. Like `/init` but for the `docs/` directory.

If `$ARGUMENTS` is provided, focus on just that module or topic. Otherwise, audit the entire project.

---

## Step 1: Detect Project Structure

Scan the project to build a structural map:

1. Read `CLAUDE.md` for project overview, module list, and conventions
2. Read the project manifest (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`) for metadata
3. Glob for top-level source directories that represent modules or services. Common patterns:
   - Monorepo services: `accounts/`, `billing/`, `api/`, etc.
   - Single app layers: `src/api/`, `src/models/`, `src/services/`
   - Library packages: `packages/`, `crates/`, `internal/`
4. For each module/service directory, quickly scan for:
   - Route definitions (API endpoints)
   - Model/schema files (database models, types)
   - Entry points (index files, main files, server setup)
5. Identify the project type: monorepo with services, single app, library, CLI tool

Store this as the **project map** — it drives the gap analysis.

---

## Step 2: Audit Existing Docs

Check for a documentation directory:

1. Glob for `docs/` at project root
2. Fallback: check `documentation/`, `doc/`
3. If no docs directory exists, create `docs/` and note that all docs are missing — skip to Step 4

If docs exist:

1. List all `.md` files in the docs directory
2. Read each file's first 5-10 lines to extract its heading and purpose
3. Map each doc to its corresponding module/topic:
   - `api-billing.md` → billing module
   - `architecture.md` → system-level
   - `data-model.md` → database/schema
   - `development.md` → setup/operations
4. For each doc, do a quick staleness check:
   - Grep the doc for file paths, function names, model names, or endpoint paths
   - Verify those references still exist in the codebase via Glob/Grep
   - If references point to files/symbols that no longer exist → mark as **stale**

---

## Step 3: Gap Analysis

Compare the project map (Step 1) against the docs inventory (Step 2).

Categorize each module/topic:

- **Current** — has a doc, references are valid
- **Stale** — has a doc, but contains outdated references
- **Missing** — module exists in code but has no corresponding doc

If `$ARGUMENTS` was provided, filter to only the specified module/topic.

Present the audit summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DOCS AUDIT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

docs/ directory: {exists (N files) | created (empty)}

CURRENT:
  ✓ {filename} — {what it covers}

STALE:
  ⚠ {filename} — {what's outdated and why}

MISSING:
  ✗ {suggested filename} — {module/topic} has {N endpoints / N models / etc.}, no doc

Proceed? (Generate missing + update stale / Pick specific / Skip)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for user confirmation before writing any files.

---

## Step 4: Detect Doc Style

Before generating or updating, detect the project's existing doc conventions. If existing docs are present, analyze them:

1. **Naming pattern**: `api-{service}.md`, `{service}-api.md`, `{service}.md`, or `{topic}.md`
2. **Heading structure**: H1 title, H2 sections, H3 subsections — what patterns are used?
3. **Content patterns**: tables for endpoints? ASCII diagrams? Code examples? Inline bash commands?
4. **Level of detail**: service capability level (endpoints, CLI commands, MCP tools) vs function-level (exports, parameters)
5. **Opening format**: quote block? plain paragraph? badge/version line?

If no existing docs, use this default structure:

```markdown
# {Module Name}

> {One-line description of what this module does}

## Overview

{2-3 sentences on the module's role in the system}

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/... | ... |

## Key Files

| File | Purpose |
|------|---------|
| src/... | ... |

## Data Models

{Key models/types this module owns or uses}
```

---

## Step 5: Generate Missing Docs

For each missing doc the user approved:

1. Read the module's source code:
   - Route/handler files → extract endpoints, methods, parameters
   - Model/schema files → extract types, fields, relationships
   - Entry point → understand module structure and exports
   - Test files → understand expected behavior
2. Generate the doc following the detected style from Step 4
3. Write the file to `docs/{detected-naming-pattern}.md`
4. Report what was created

---

## Step 6: Update Stale Docs

For each stale doc the user approved:

1. Read the current doc in full
2. Read the current code for the corresponding module
3. Identify specific stale sections:
   - References to removed files, functions, or models
   - Endpoints that have been added, removed, or changed
   - Configuration or setup steps that have changed
4. Rewrite only the stale sections — preserve:
   - The doc's overall structure and heading hierarchy
   - Manually-written context, explanations, and design rationale
   - Diagrams and examples that are still accurate
5. Edit the file in place using the Edit tool
6. Report what was changed

---

## Step 7: Update CLAUDE.md Reference

After generating or updating docs, check if `CLAUDE.md` has a reference or docs section (look for patterns like `@docs/`, `docs/`, or a "Reference" heading).

If it does:
- Add entries for any newly created docs, following the existing format
- Example: `- **docs/api-accounts.md** — accounts service API reference`

If it doesn't:
- Skip this step — don't create a reference section that doesn't already exist

---

## Step 8: Summary

Present a final summary of all changes:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DOCS UPDATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Created:
  + docs/api-accounts.md (accounts service — 16 endpoints)
  + docs/api-gateway.md (API gateway routes)

Updated:
  ~ docs/api-cal.md (removed stale CalendarSync references, added new BookingType endpoints)

CLAUDE.md:
  + Added docs/api-accounts.md reference
  + Added docs/api-gateway.md reference

No action needed:
  ✓ docs/architecture.md
  ✓ docs/api-billing.md
  ✓ docs/api-time.md
  ✓ docs/data-model.md
  ✓ docs/development.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
