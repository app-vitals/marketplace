---
name: learning-capture
description: >
  This skill captures learnings to staging. Triggers on: "that worked", "it's fixed",
  "working now", "problem solved", "save this", "remember this", /learn command,
  or when user corrects Claude ("use X instead of Y", "no, do X", "always X",
  "never Y", "I prefer X"). Also trigger after solving non-obvious problems together.
---

# Learning Capture

Capture learnings to the staging area in `CLAUDE.local.md`.

**Keep it simple**: Just capture the insight. Don't over-structure. `/learn-promote` will figure out where it belongs.

## Two-Phase Approach

1. **Capture (this skill)**: Quick, lightweight staging
2. **Promote (/learn-promote)**: Smart routing to CLAUDE.md or skills

## When to Capture

**Capture when you notice:**
- User corrects you ("use X instead of Y", "no, do X")
- A non-obvious solution is discovered together
- User states a preference ("I prefer X", "always do Y")
- User explicitly asks to save something
- Trigger phrases: "that worked", "it's fixed", "problem solved"

**Don't capture:**
- Trivial or one-time instructions
- Things already documented
- Vague statements without actionable content

## Capture Protocol

### Step 1: Check for Duplicates

Search `CLAUDE.local.md` for similar content:

```bash
grep -i "keyword" CLAUDE.local.md
```

If similar exists, don't duplicate. Offer to update if the new learning adds context.

### Step 2: Identify the Core Insight

Ask yourself:
- What's the actionable takeaway?
- Is it reusable for future sessions?
- Can it be stated simply?

### Step 3: Propose Briefly

Keep proposals minimal - don't interrupt the flow:

```
Got it - want me to save "use uv instead of pip" as a learning?
```

Or for discoveries:

```
That was a non-obvious fix. Save to learnings?
"Prisma pool errors in serverless → use connection pooling"
```

### Step 4: Save on Approval

Add to the `# Staged Learnings` section in `CLAUDE.local.md` (gitignored):

```markdown
# Staged Learnings

- Use uv instead of pip for Python package management
- Always run tests before committing

# Personal Learnings
(these are already promoted/permanent - don't add here)
```

**IMPORTANT**: Always add new learnings under `# Staged Learnings`, never under other sections. If the section doesn't exist, create it at the top of the file. The `# Personal Learnings` section (and any other sections) contains already-promoted items that should not be mixed with staged ones.

**Format**: Just a simple bullet point. Natural language. No complex tags.

### Step 5: Confirm

```
Saved to staged learnings. Run /learn-promote when ready to route.
```

## Quality Filters

**Skip if:**
- Too vague ("do it differently")
- One-time ("just this once")
- Already exists
- Not actionable

**Capture if:**
- Would help future sessions
- Required discovery to learn
- User explicitly corrected behavior

## File Location

All staged learnings go to `CLAUDE.local.md` (automatically gitignored).

For promotion to final destinations, use `/learn-promote`.
