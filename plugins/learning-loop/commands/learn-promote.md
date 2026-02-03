---
name: learn-promote
description: Route staged learnings to their final destination
argument-hint: "[learning]"
allowed-tools:
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - Skill
---

# /learn-promote - Route Staged Learnings

Intelligently route staged learnings to their final destination.

## Usage

```
/learn-promote
/learn-promote "use uv instead of pip"
```

## The Routing Philosophy

**Be smart, not structured.** Analyze the learning, find related skills, and put it in the right place:

- Simple preference? → Add to CLAUDE.md as an instruction
- Related to an existing skill? → Update that skill
- Complex workflow? → Maybe create a new skill

## Process

### Step 1: Show Staged Learnings

Read `.claude/CLAUDE.md` and display staged learnings:

```
## Staged Learnings (3)

1. Use uv instead of pip for Python package management
2. Always run tests before committing
3. ralph loop: check progress.md before starting

Select (1-3), 'all', or 'skip':
```

### Step 2: Analyze Each Learning

For each selected learning, analyze:

1. **What type is it?**
   - Correction (user corrected behavior)
   - Preference (style/approach choice)
   - Discovery (non-obvious solution)
   - Workflow tip (related to a specific tool/skill)

2. **Search for related skills:**
   ```bash
   # Search project skills
   rg -i "keyword" .claude/skills/ 2>/dev/null

   # Search user skills
   rg -i "keyword" ~/.claude/skills/ 2>/dev/null

   # Search plugin skills
   rg -i "keyword" ~/.claude/plugins/*/skills/ 2>/dev/null
   ```

3. **Determine best destination**

### Step 3: Smart Matching

**Example: "ralph loop: check progress.md before starting"**

```
Analyzing: "ralph loop: check progress.md before starting"

Searching for related skills...
Found: ~/.claude/plugins/app-vitals-marketplace/ralph-orchestrator/skills/ralph/

This learning relates to the ralph-orchestrator plugin.

Recommendation: Update existing ralph skill
  - Or: Add to CLAUDE.md as workflow reminder
  - Or: Contribute to marketplace (creates PR)

Choose destination:
```

**Example: "Always run tests before committing"**

```
Analyzing: "Always run tests before committing"

Searching for related skills...
Found: ~/.claude/skills/commit-workflow/ (if exists)

Recommendation:
  - If commit skill exists → Update it
  - If no related skill → Add to CLAUDE.md

Choose destination:
```

### Step 4: Route to Destination

#### → CLAUDE.md Instruction (Most Common)

For simple preferences and reminders, add directly to CLAUDE.md:

```markdown
# Project Instructions

- Use uv instead of pip for Python package management
- Always run tests before committing
```

Just add as a bullet point in the appropriate place. No special section needed.

#### → Update Existing Skill

If the learning relates to an existing skill:

1. Read the skill's SKILL.md
2. Find the appropriate section
3. Add the learning as guidance
4. Show diff for confirmation

#### → Create New Skill

If the learning is complex enough to warrant a new skill:

1. Invoke `plugin-dev:skill-development` for guidance
2. Create skill structure
3. Choose location (project or user level)

#### → Contribute to Marketplace

If the learning improves a marketplace plugin:

1. Locate the plugin repo
2. Create branch and PR
3. Use contribution template

### Step 5: Clean Up Staging

After successful promotion:
- Remove the learning from `## Staged Learnings`
- If section is empty, leave just the header

## Decision Hints

| Learning Pattern | Likely Destination |
|------------------|-------------------|
| "use X instead of Y" | CLAUDE.md instruction |
| "always/never do X" | CLAUDE.md instruction |
| "for [tool], do X" | Update related skill |
| Multi-step workflow | Consider new skill |
| Plugin-specific tip | Contribute to marketplace |

## Batch Mode

When promoting multiple learnings:

```
Batch routing:

1. "Use uv instead of pip"
   → CLAUDE.md instruction

2. "Always run tests before committing"
   → CLAUDE.md instruction (or update commit skill if exists)

3. "ralph loop: check progress.md"
   → Update ralph skill (or contribute to marketplace)

Accept recommendations? [Yes / Review each / Skip]
```

## Tips

- Let learnings accumulate before promoting
- Trust the matching - it searches existing skills
- Most learnings just become CLAUDE.md instructions
- Skills are for complex, reusable workflows
- Marketplace contributions help everyone
