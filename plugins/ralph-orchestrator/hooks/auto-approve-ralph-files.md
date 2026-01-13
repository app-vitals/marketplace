---
name: auto-approve-ralph-files
description: Auto-approve tools during Ralph loop execution for autonomous operation
event: PreToolUse
match_tools: Edit,Write,Read,WebSearch,WebFetch
---

# Auto-approve Tools for Ralph Loop

Enable autonomous Ralph loop execution by auto-approving safe tool calls.

## Tools Auto-Approved

### Always Approved (Read-Only / Research)
These tools don't modify the codebase and are safe to auto-approve unconditionally:

- **Read** - Reading any file for context gathering
- **WebSearch** - Web searches for research
- **WebFetch** - Fetching web content for analysis

### Conditionally Approved (Write Operations)
These tools modify files and are only approved for Ralph working files:

- **Edit** - Only for `.claude/ralph/**` files
- **Write** - Only for `.claude/ralph/**` files

## Decision Logic

```
IF tool is Read, WebSearch, or WebFetch:
    → APPROVE (always safe, read-only operations)

IF tool is Edit or Write:
    IF file_path contains ".claude/ralph/":
        → APPROVE (Ralph working file)
    ELSE:
        → PASS (let normal permission flow handle it)
```

## Response Format

Return JSON:
- To approve: `{"decision": "approve"}`
- To pass to normal flow: `{"decision": "pass"}`

## Files Auto-Approved for Write

When Edit or Write targets these patterns, approve automatically:
- `.claude/ralph/*/progress.md` - Iteration tracking and learnings
- `.claude/ralph/*/AGENTS.md` - Task-specific patterns
- `.claude/ralph/*/plan.json` - Phase completion status
- `.claude/ralph/*/prd.json` - Story completion status
- `.claude/ralph/*/PLAN.md` - Human-readable plan
- `.claude/ralph/*/PRD.md` - Human-readable PRD
- `.claude/ralph/*/*.md` - Any markdown in Ralph working directory
- `.claude/ralph/*/*.json` - Any JSON in Ralph working directory

## Why This Hook Exists

Ralph loops are designed to be autonomous. The loop:
1. Reads codebase files for context (Read tool)
2. Searches the web for documentation (WebSearch, WebFetch)
3. Updates progress.md after each action to maintain state (Edit, Write)

Prompting for permission breaks the autonomous flow and defeats the purpose of the loop.

**Read-only tools** are always safe - they don't change anything.

**Write operations** to `.claude/ralph/` are safe because these files are:
- Located in a dedicated working directory
- Created by the Ralph system itself
- Not production code
- Used only for loop state management
