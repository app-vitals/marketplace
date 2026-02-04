---
name: learn
description: Capture a learning to staging
argument-hint: "<insight>"
allowed-tools:
  - Read
  - Edit
  - Glob
  - AskUserQuestion
---

# /learn - Capture Learning

Quickly capture a learning to the staging area.

## Usage

```
/learn <insight>
```

## Examples

```
/learn use uv instead of pip
/learn always run tests before committing
/learn ralph loop: check progress.md before starting
/learn Next.js SSR errors show in terminal, not browser console
```

## Process

1. **Parse the insight** provided by the user

2. **Check for duplicates** in `CLAUDE.local.md`

3. **Preview before saving:**
   ```
   Staging this learning:

   Content: Use uv instead of pip for package management
   Destination: CLAUDE.local.md (gitignored)

   Stage this? [Yes / No / Edit]
   ```

4. **On approval:**
   - Ensure `CLAUDE.local.md` exists
   - Add as simple bullet point
   - Confirm: "Saved to staged learnings."

## Without Arguments

If user runs `/learn` without arguments:

1. Ask: "What would you like to capture?"
2. Offer suggestions based on recent conversation

## Format

Learnings are staged in `CLAUDE.local.md` as simple bullet points:

```markdown
# Staged Learnings

- Use uv instead of pip for Python package management
- Always run tests before committing
- ralph loop: check progress.md before starting
```

**Keep it natural**: Just write what you learned. No special syntax needed.

**Why CLAUDE.local.md?** It's gitignored by default - staged learnings are private until you promote them to a shared location.

## What Happens Next

Staged learnings wait for `/learn-promote` which:
- Analyzes each learning
- Matches to existing skills if relevant
- Routes to the right place (CLAUDE.md instruction or skill file)

## Tips

- Keep it simple - just write the insight naturally
- Be specific: "use uv instead of pip" > "use better tools"
- Include context if helpful: "Next.js SSR errors: check terminal"
- Run `/learn-promote` periodically to process staged learnings
