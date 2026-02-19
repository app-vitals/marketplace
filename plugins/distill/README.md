# distill

Distill conversations into persistent context files. Like `/compact` but stores to your project files — extracting long-term facts, goals, and decisions that survive across `/clear` cycles.

## Commands

### `/distill:distill`

Distills the current conversation into structured context files in a `context/` directory. Run this before clearing the conversation to preserve important information.

**What it does:**
- Reviews the full conversation for key information, decisions, and goals
- Creates or updates files in `context/` organized by topic
- Maintains a `context/index.md` describing what's available and when to load it
- Archives the session in `context-archive/YYYY-MM-DD-topic.md`
- Reminds you to run `/clear` to reset with context intact

**Usage:**
```
/distill:distill
/distill:distill focus on the architecture decisions we made
```

## Context File Patterns

The command organizes context into files based on what was discussed:

| File | Contents |
|------|----------|
| `context/goals.md` | Goals, deadlines, progress tracking |
| `context/business.md` | Clients, team, metrics, operations |
| `context/strategy.md` | Strategic decisions, positioning, pivots |
| `context/decisions.md` | Significant decisions with rationale |
| `context/index.md` | Index of all files with load-when guidance |
| `context-archive/*.md` | Session-by-session history |

## Workflow

1. Work with Claude on a topic
2. Run `/distill:distill` when the conversation gets long or you're ready to move on
3. Review the created/updated context files
4. Run `/clear` to start fresh
5. In your next session, load relevant context files with `@context/goals.md` etc.
