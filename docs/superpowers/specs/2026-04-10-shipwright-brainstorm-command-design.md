# Shipwright `/brainstorm` Command — Design Spec

**Date:** 2026-04-10
**Status:** Approved (awaiting user review before implementation planning)
**Author:** Brainstorming session with David O'Dell

---

## Summary

Add a new `/brainstorm` slash command to the shipwright plugin. It runs an interactive, shipwright-native brainstorming session that produces a rich PRD at `planning/<folder>/PRD.md`, formatted for direct consumption by the existing `/plan-session <folder>` command.

This fills the current gap in the shipwright pipeline: users have to bring their own input documents to `/plan-session`, but there's no structured way to turn a rough idea into those inputs. `/brainstorm` becomes the new front door.

---

## Motivation

Current shipwright flow:

```
(user brings input docs) → /plan-session → /dev-task → /review → ship
```

Gap: `/plan-session` Phase 2 is good at extracting requirements from documents, but there's no shipwright-provided way to *create* those documents. Users who don't already have a spec are stuck.

Existing alternatives fall short:
- `superpowers:brainstorming` is general-purpose and doesn't produce shipwright-shaped output
- `ralph-orchestrator:/prd` writes to `.claude/ralph/<task>/` and is structured for Ralph loops, not shipwright's `planning/` folder
- Manual spec-writing has no consistency guarantee

Target flow after this change:

```
/brainstorm → /plan-session → /dev-task → /review → ship
```

---

## Design Decisions

Four forks were resolved during the brainstorming session:

| Decision | Choice | Rationale |
|---|---|---|
| **Brainstorm style** | Shipwright-native structured template-fill | Produces cleaner input for plan-session Phase 2 than general-purpose brainstorming; keeps shipwright self-contained without a hard dependency on the superpowers plugin |
| **Folder argument** | Optional positional arg (`/brainstorm [folder-name]`) | Supports both power users (pre-named) and discovery flows (name emerges at end) |
| **PRD depth** | Rich PRD (9 sections, opt-in depth menu) | User prefers more information to maximize `/plan-session` success |
| **Codebase awareness** | Light grounding (toolchain + CLAUDE.md at start) | Avoids duplicating the deep research already done in plan-session Phase 2; respects shipwright's "don't build speculatively" principle |

---

## Architecture

### File Layout

**New file:** `plugins/shipwright/commands/brainstorm.md`

Self-contained markdown command. No new agents, skills, references files, or JSON sidecars.

**Frontmatter:**

```yaml
---
description: Interactive brainstorming session that produces a rich PRD consumable by /plan-session
arguments:
  - name: folder-name
    description: Optional planning folder name (e.g., april-2026-workspace-switcher). If omitted, derived at the end.
    required: false
---
```

**Output:** `planning/<folder-name>/PRD.md`

The output path is deliberately the same folder `/plan-session <folder-name>` reads from, so handoff is automatic — no wiring changes needed in `/plan-session`.

### Phase Flow

The command runs 6 phases in order, auto-advancing between them unless a user response is needed.

#### Phase 0: Light Grounding

Silent context gathering at start:

1. Scan project root for toolchain indicators: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`
2. Read `CLAUDE.md` if it exists
3. Read `planning/PRODUCT-SPEC.md` if it exists
4. Quick directory scan to identify likely layers (`src/`, `app/`, `api/`, `components/`, etc.)
5. Store findings internally; surface only as confirmation at the start of Phase 1

Grounding is used to **avoid blind questions** ("what language are you using?") rather than to drive deep research. Deep research belongs in `/plan-session` Phase 2, which already has it.

#### Phase 1: Opening & Scope Framing

2–3 questions:

1. "What problem are you solving, in 1–2 sentences?"
2. "Is this a new capability, an extension of existing functionality, or a rewrite?" (multiple choice)
3. Confirm detected toolchain from Phase 0: "I see this is a {detected} project — correct?"

#### Phase 2: Core PRD Interview

Walks through the 5 required sections. Questions asked **one at a time**, multiple-choice preferred where possible.

1. **Problem & Motivation** — deeper why, current pain points
2. **Users & Use Cases** — who benefits, primary flows
3. **Features** — loop: "describe the next feature" → "acceptance criteria?" → "priority (Must / Should / Nice)?" → "any more features?" Loop continues until user says no. No cap on feature count.
4. **Constraints** — deadlines, technical constraints, organizational constraints
5. **Out-of-Scope** — explicit non-goals to prevent scope creep

#### Phase 3: Depth Menu (Opt-In Rich Sections)

After the core interview, present a menu:

```
Want to go deeper on any of these? (pick any, or 'done')

  1. Success Metrics — how we measure success
  2. UX/UI Notes — mockup descriptions, interaction details, states
  3. Technical Preferences — stack choices, patterns to follow/avoid
  4. Open Questions — known unknowns to flag for plan-session
```

Each picked section runs 2–5 follow-up questions. User can pick multiple or all. Sections not picked are **omitted entirely** from the PRD — no "TBD" placeholders (which would fail plan-session Phase 5 quality checks).

#### Phase 4: Draft & Review

1. Render the PRD as markdown
2. Show it to the user
3. Iterate on feedback (add/remove/edit sections) until the user approves

#### Phase 5: Save & Handoff

1. If no folder arg was provided, suggest 3 kebab-case names based on the problem statement (e.g., `2026-04-workspace-switcher`). User picks or overrides.
2. Check for existing files at `planning/<folder>/`:
   - If `PRD.md` already exists: ask overwrite / append timestamp (`PRD-2026-04-10.md`) / cancel
   - Other files in the folder are left untouched
3. Create `planning/<folder>/` if it doesn't exist
4. Write the PRD
5. Print the handoff banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BRAINSTORM COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRD written: planning/{folder}/PRD.md

Summary:
  Features:          {N} ({must} must-have, {should} should-have, {nice} nice-to-have)
  Constraints:       {N} captured
  Optional sections: {list of included rich sections}

NEXT: /plan-session {folder}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

The command does **not** auto-invoke `/plan-session`. User controls the transition, matching shipwright's per-command pattern.

---

## PRD Output Format

```markdown
# PRD: {Project Name}

**Created:** {YYYY-MM-DD}
**Status:** Draft (ready for /plan-session)
**Toolchain detected:** {e.g., Node.js (pnpm) + React}

---

## 1. Problem & Motivation
{1–2 paragraphs — the why}

## 2. Users & Use Cases
- **Primary users:** {who}
- **Primary flows:**
  1. {flow 1}
  2. {flow 2}

## 3. Features

### F1: {Feature Name}
**Description:** {what it does}
**Acceptance criteria:**
- [ ] {criterion 1}
- [ ] {criterion 2}
**Priority:** {Must-have | Should-have | Nice-to-have}

### F2: {Feature Name}
...

## 4. Constraints
- **Deadlines:** {dates or "none"}
- **Technical:** {frameworks, integrations, performance targets}
- **Organizational:** {team, compliance, budget}

## 5. Out of Scope
- {explicit non-goal 1}
- {explicit non-goal 2}

---

## 6. Success Metrics *(optional — present if captured)*
- {metric 1 — how we know it worked}

## 7. UX / UI Notes *(optional)*
- **Layout:** {description or ASCII wireframe}
- **Interactions:** {key behaviors}
- **States:** {empty, loading, error, success}

## 8. Technical Preferences *(optional)*
- **Stack choices:** {preferred libraries/patterns}
- **Follow:** {existing patterns to mirror}
- **Avoid:** {anti-patterns to skip}

## 9. Open Questions *(optional)*
- [ ] {unresolved decision 1}
- [ ] {unresolved decision 2}

---

## Handoff Notes for /plan-session
{Auto-generated 2–3 sentence summary flagging items plan-session should pay special attention to — high-risk features, ambiguous requirements, tight deadlines.}
```

### Format Design Choices

- **MoSCoW feature priorities** (Must/Should/Nice) — plan-session can use these to order the task breakdown
- **Acceptance criteria as markdown checkboxes** — plan-session Phase 2 reads these directly into requirements extraction
- **Handoff Notes section** — auto-written by the command based on what surfaced in the interview; gives plan-session a "here's what to watch out for" preamble without needing to re-derive it
- **Optional sections omitted entirely** when not picked in Phase 3 — no empty "TBD" sections that would fail plan-session Phase 5 quality checks

---

## Edge Cases

| Scenario | Behavior |
|---|---|
| Folder already exists with other files | List the files, keep them, ask about PRD.md only |
| `PRD.md` already exists | Prompt: (a) overwrite `PRD.md`, (b) write new file with timestamp (`PRD-2026-04-10.md`) alongside the existing one, or (c) cancel. Note: `/plan-session` reads **all** markdown files in the folder, so option (b) means both PRDs will be consumed — useful for iteration but the user should be aware |
| No folder arg + user can't think of a name | Suggest 3 kebab-case names derived from the problem statement |
| User abandons mid-session | No partial PRD written — command only writes at Phase 5 |
| `planning/` directory doesn't exist yet | Create `planning/<folder>/` on save; don't pre-create in Phase 0 |

---

## YAGNI — Explicitly Out of Scope

- **No JSON sidecar** (`prd.json`) — `/plan-session` reads markdown directly; a JSON file would be dead weight
- **No schema validation** — `/plan-session` Phase 2 already handles malformed input gracefully
- **No learning-loop integration at the brainstorm phase** — can be added later if gaps emerge
- **No "edit existing PRD" mode** — if the user wants to edit, they open the file directly
- **No draft save / resume** — abandoning mid-session loses the conversation; acceptable trade-off for v1

---

## Plugin Updates Required

Beyond the new `commands/brainstorm.md` file:

1. `plugins/shipwright/README.md` — add `/brainstorm` to the command list
2. `plugins/shipwright/plan.md` — note that brainstorm is now the front door before plan-session
3. `plugins/shipwright/TESTING.md` — append test cases (see below)
4. `plugins/shipwright/.claude-plugin/plugin.json` — bump patch version
5. `README.md` (repo root) — bump shipwright version in the plugin table
6. `.claude-plugin/marketplace.json` — bump root version (patch)

---

## Testing Plan

Added to `plugins/shipwright/TESTING.md`:

1. `/brainstorm` with no args → full interactive flow, derives folder name at end
2. `/brainstorm my-feature` → uses provided folder, skips name-derivation
3. `/brainstorm existing-folder` where `planning/existing-folder/PRD.md` already exists → overwrite/append/cancel prompt fires
4. **End-to-end test:** run `/plan-session <folder>` immediately after `/brainstorm` → verify Phase 2 extracts features, acceptance criteria, and constraints cleanly from the PRD. This is the critical integration test.
5. Skip all optional sections in Phase 3 → verify PRD contains only sections 1–5 plus Handoff Notes (no empty section headers)

---

## Success Criteria

- `/brainstorm` runs end-to-end without errors for a new project
- Output `PRD.md` passes `/plan-session` Phase 2 extraction with no warnings
- Features, acceptance criteria, constraints, and out-of-scope items survive the PRD → plan-session handoff intact
- Priority tags (Must/Should/Nice) influence the task breakdown ordering in `/plan-session`
- Command is idempotent with respect to other files in the `planning/<folder>/` directory (doesn't touch them)
