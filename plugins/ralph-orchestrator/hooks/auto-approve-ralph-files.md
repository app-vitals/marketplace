---
name: auto-approve-ralph-files
description: Auto-approve write operations to Ralph working files (.claude/ralph/)
---

# Auto-Approve Ralph Files Hook

Auto-approve Edit and Write operations to Ralph working directory files.

## Decision Logic

Check the `file_path` parameter:

1. **If path contains `.claude/ralph/`** → Approve (these are Ralph working files)
2. **Otherwise** → Pass (let default permission handling decide)

## Output

Return JSON with decision:
- `{"decision": "approve"}` - Auto-approve this operation
- `{"decision": "pass"}` - Defer to default handling

## Examples

| Operation | Path | Decision |
|-----------|------|----------|
| Write | `.claude/ralph/my-task/progress.md` | approve |
| Edit | `.claude/ralph/my-task/prd.json` | approve |
| Write | `src/main.ts` | pass |
| Edit | `README.md` | pass |
