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
- Not ready yet? → Keep as personal learning (bakes locally)

## Process

### Step 1: Show Staged Learnings

Read `CLAUDE.local.md` and display staged learnings:

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

   # Search plugin skills (cached)
   rg -i "keyword" ~/.claude/plugins/*/skills/ 2>/dev/null
   ```

3. **Determine best destination** - Use skills to help decide:
   - `claude-md-management:claude-md-improver` - audit CLAUDE.md files, decide if learning fits there
   - `plugin-dev:skill-development` - evaluate if learning belongs in a skill

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

#### → Keep as Personal Learning

If the learning isn't ready to promote yet, move it from "Staged" to "Personal" in `CLAUDE.local.md`:

```markdown
# Staged Learnings
- (other staged items)

# Personal Learnings
- The learning that's still baking
```

Personal learnings stay local and accumulate. As the list grows, **categorize** related ones under headings. When patterns emerge, promote the insight.

#### → CLAUDE.md Instruction (Most Common)

For simple preferences and reminders, route to the appropriate CLAUDE.md file.

**Use `claude-md-management:claude-md-improver`** to audit existing CLAUDE.md files and determine the best placement for the learning. This skill evaluates quality and suggests improvements.

**Choose the right file:**

| Learning Type | Destination | Example |
|--------------|-------------|---------|
| Team-shared preference | `./CLAUDE.md` or `./.claude/CLAUDE.md` | "Use uv instead of pip" |
| Personal preference | `./.claude.local.md` (gitignored) | "I prefer verbose output" |
| Package-specific | `./packages/foo/CLAUDE.md` | "This package uses Jest" |
| User-wide default | `~/.claude/CLAUDE.md` | "Always use TypeScript" |

Ask the user if unclear: "Is this a team preference or personal?"

**Add concisely** - one line per concept. CLAUDE.md is part of the prompt. Avoid verbose explanations.

#### → Update Existing Skill

If the learning relates to an existing skill:

**Use `plugin-dev:skill-development`** for guidance on skill structure and best practices.

1. Read the skill's SKILL.md
2. Find the appropriate section
3. Add the learning as guidance
4. Show diff for confirmation

#### → Create New Skill

If the learning is complex enough to warrant a new skill:

**Use `plugin-dev:create-plugin`** for guided end-to-end plugin creation with component design, implementation, and validation.

#### → Contribute to Marketplace

If the learning improves a marketplace plugin:

**Use the appropriate `plugin-dev:*-development` skill** for guidance:
- `plugin-dev:skill-development` - for updating or creating skills
- `plugin-dev:command-development` - for updating or creating commands
- `plugin-dev:hook-development` - for updating or creating hooks

**Step 1: Check configured marketplaces for local sources**
```bash
cat ~/.claude/plugins/known_marketplaces.json
```

Example output:
```json
{
  "claude-plugins-official": {
    "source": { "source": "github", "repo": "anthropics/claude-plugins-official" },
    "installLocation": "/Users/dan/.claude/plugins/marketplaces/claude-plugins-official"
  },
  "app-vitals-marketplace": {
    "source": { "source": "directory", "path": "/Users/dan/src/app-vitals-marketplace" },
    "installLocation": "/Users/dan/src/app-vitals-marketplace"
  }
}
```

**Step 2: Determine destination based on marketplace source**

If the marketplace entry has `"source": "directory"`:
- This is a **local marketplace** - the user likely cloned it for contribution
- Write to `installLocation/plugins/<plugin-name>/` (same as `source.path`)
- User can commit and create PR in their normal workflow

If the marketplace entry has `"source": "github"`:
- This is a **remote marketplace** - don't write to the cache (changes will be overwritten on upgrade)
- Instead, promote the learning to `CLAUDE.md` or stage it in `CLAUDE.local.md` as a personal reminder
- Add a note: "To contribute this upstream, clone the marketplace repo, install it as a local directory source, make the change, and submit a PR"

**Example: Learning from a local marketplace plugin (pr-review)**

```
Learning: "pr-review: always check for draft PRs before posting"

Checking ~/.claude/plugins/known_marketplaces.json...
Found: app-vitals-marketplace → source: directory, path: ~/src/app-vitals-marketplace

pr-review is from app-vitals-marketplace (local source).
Writing to: ~/src/app-vitals-marketplace/plugins/pr-review/skills/...

✓ Updated source. You can commit and create a PR when ready.
```

**Example: Learning from a remote marketplace plugin (github source)**

```
Learning: "claude-plugins-official/some-plugin: prefer X over Y"

Checking ~/.claude/plugins/known_marketplaces.json...
Found: claude-plugins-official → source: github, repo: anthropics/claude-plugins-official

This marketplace is remote - changes to the cache will be overwritten on upgrade.

Routing to CLAUDE.md instead:
  + some-plugin: prefer X over Y

✓ Saved to CLAUDE.md.

Note: To contribute this upstream, clone https://github.com/anthropics/claude-plugins-official,
install it as a local directory source (`claude plugin marketplace add --dir /path/to/clone`),
make your change, and submit a PR.
```

### Step 5: Clean Up Staging

After successful promotion:
- Remove the learning from the Staged section
- If moved to Personal, it stays in `CLAUDE.local.md` under Personal Learnings
- If no staged or personal learnings remain, delete the file entirely
- Do NOT leave comments like `<!-- promoted to X -->` - they add noise and confusion

## Decision Hints

| Learning Pattern | Likely Destination |
|------------------|-------------------|
| "use X instead of Y" | CLAUDE.md instruction |
| "always/never do X" | CLAUDE.md instruction |
| "for [tool], do X" | Update related skill |
| Multi-step workflow | Consider new skill |
| Plugin-specific tip | Marketplace source (if local) or cached |
| Single observation, not pattern yet | Keep as personal learning |
| Vague/uncertain preference | Keep as personal, watch for pattern |

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
