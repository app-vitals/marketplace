---
name: learning-review
description: >
  This skill shows staged learnings. Triggers on: "review learnings",
  "what's staged", "show learnings", "list learnings", or /learn-review.
---

# Learning Review

Show and manage staged learnings.

## When This Activates

- User asks to see learnings
- User wants to edit or delete staged items
- Before running /learn-promote

## Process

### Step 1: Read Staged Learnings

Read `CLAUDE.local.md` (the entire file is staged learnings).

### Step 2: Display

```
## Staged Learnings (3)

1. Use uv instead of pip for Python package management
2. Always run tests before committing
3. ralph loop: check progress.md before starting

Run /learn-promote to route these to their final destination.
```

### Step 3: Offer Actions

- **Edit** - Modify a learning's text
- **Delete** - Remove from staging
- **Promote** - Start the promotion flow

## File Location

Staged learnings are in `CLAUDE.local.md` (gitignored by default).
