---
name: learn-review
description: Review staged learnings
allowed-tools:
  - Read
  - Edit
  - Glob
---

# /learn-review - Review Staged Learnings

See what's been captured and waiting for promotion.

## Usage

```
/learn-review
```

## Process

1. **Read `CLAUDE.local.md`**

2. **Show staged learnings:**
   ```
   ## Staged Learnings (3)

   1. Use uv instead of pip for Python package management
   2. Always run tests before committing
   3. ralph loop: check progress.md before starting

   Actions:
   - /learn-promote to route these to final destinations
   - Edit or delete individual learnings below
   ```

3. **Offer actions:**
   - Edit a learning
   - Delete a learning
   - Promote all

## Actions

- **Edit** - Modify the learning text
- **Delete** - Remove from staging
- **Promote** - Run /learn-promote

## What's Not Here

This just shows staged learnings. Once promoted, learnings live in:
- CLAUDE.md (as regular instructions)
- Skill files (`.claude/skills/` or `~/.claude/skills/`)
