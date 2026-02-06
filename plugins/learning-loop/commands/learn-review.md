---
name: learn-review
description: Review staged learnings
allowed-tools:
  - Read
  - Edit
  - Glob
---

# /learn-review - Review Learnings

See what's been captured - both staged (ready to promote) and personal (baking locally).

## Usage

```
/learn-review
```

## Process

1. **Read `CLAUDE.local.md`**

2. **Show both sections:**
   ```
   ## Staged Learnings (2)
   Ready to promote to CLAUDE.md, skills, or plugins.

   1. ralph loop: check progress.md before starting
   2. Always run tests before committing

   ## Personal Learnings (3)
   Baking locally. Watch for patterns to emerge.

   - Use uv instead of pip
   - Prefer explicit imports over wildcards
   - Check CI status before reviewing PRs

   Actions:
   - /learn-promote to route staged learnings
   - Edit or delete individual items
   ```

3. **Offer actions:**
   - Edit a learning
   - Delete a learning
   - Move between staged/personal
   - Promote staged learnings

## CLAUDE.local.md Structure

```markdown
# Staged Learnings
- Ready to promote somewhere

# Personal Learnings
- Observation baking locally
- Another preference

## [Category] (emerges as list grows)
- Related learning 1
- Related learning 2
```

## Actions

- **Edit** - Modify the learning text
- **Delete** - Remove entirely
- **Unstage** - Move from staged to personal (not ready to promote yet)
- **Stage** - Move from personal to staged (ready to promote)
- **Promote** - Run /learn-promote on staged learnings
- **Categorize** - Group related personal learnings under a heading

## Personal Learnings

Personal learnings are observations that:
- Aren't ready to promote yet
- Might become patterns over time
- Are useful locally but not universally

As the list grows, **categorize** related learnings under headings. When a pattern emerges across multiple learnings, consider promoting the insight.
