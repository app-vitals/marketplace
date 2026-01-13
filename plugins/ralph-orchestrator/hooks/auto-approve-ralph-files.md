---
name: auto-approve-ralph-files
description: Auto-approve edits to Ralph working files (.claude/ralph/**) to enable autonomous loop execution
event: PreToolUse
match_tools: Edit,Write
---

# Auto-approve Ralph Working Files

Check if this edit targets a Ralph working file. If so, approve it automatically to enable uninterrupted loop execution.

## Files to Auto-Approve

Auto-approve edits to these patterns:
- `.claude/ralph/*/progress.md` - Iteration tracking and learnings
- `.claude/ralph/*/AGENTS.md` - Task-specific patterns
- `.claude/ralph/*/plan.json` - Phase completion status
- `.claude/ralph/*/prd.json` - Story completion status
- `.claude/ralph/*/PLAN.md` - Human-readable plan
- `.claude/ralph/*/PRD.md` - Human-readable PRD
- `.claude/ralph/*/*.md` - Any markdown in Ralph working directory
- `.claude/ralph/*/*.json` - Any JSON in Ralph working directory

## Logic

Check the `file_path` parameter of the Edit or Write tool:

1. If path contains `.claude/ralph/` → **APPROVE** (return `{"decision": "approve"}`)
2. Otherwise → **PASS** (return `{"decision": "pass"}` to let normal permission flow handle it)

## Response Format

Return JSON:
- To approve: `{"decision": "approve"}`
- To pass to normal flow: `{"decision": "pass"}`

## Why This Hook Exists

Ralph loops are designed to be autonomous. The loop updates progress.md after each action to maintain state across iterations. Prompting for permission breaks the autonomous flow and defeats the purpose of the loop.

These files are:
- Located in a dedicated `.claude/ralph/` directory
- Created by the Ralph system itself
- Not production code
- Safe to edit automatically
