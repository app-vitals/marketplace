# Learning Loop

A Claude Code plugin that captures what you teach Claude and puts it in the right place.

## The Problem

Every time you correct Claude ("use uv, not pip") or discover something non-obvious together, that knowledge could:
- Stay as an instruction in CLAUDE.md
- Become part of an existing skill
- Become a new skill

But figuring out where it belongs interrupts your flow.

## The Solution

Learning Loop separates **capture** from **routing**:

1. **Capture**: Quick staging while you work (simple bullet points)
2. **Promote**: Smart routing to the right destination (when you're ready)

## How It Works

### 1. Capture

As you work, Claude notices corrections and discoveries:

```
Got it - want me to save "use uv instead of pip" as a learning?
```

Or capture manually:

```
/learn always run tests before committing
```

Learnings are staged simply in `.claude/CLAUDE.md`:

```markdown
## Staged Learnings

- Use uv instead of pip for Python package management
- Always run tests before committing
- ralph loop: check progress.md before starting
```

### 2. Promote

When you're ready, route learnings to their final home:

```
/learn-promote
```

Learning Loop analyzes each learning and recommends:

- **CLAUDE.md instruction** → Simple preferences and reminders
- **Update existing skill** → If it relates to a skill you have
- **Create new skill** → If it's complex enough to warrant one
- **Contribute to marketplace** → Share improvements with others

## Commands

| Command | Description |
|---------|-------------|
| `/learn <insight>` | Capture a learning to staging |
| `/learn-review` | See staged learnings |
| `/learn-promote` | Route learnings to final destination |

## Installation

```bash
claude plugins install learning-loop
```

## The Philosophy

**Keep capture simple.** Just write what you learned naturally:
- "use uv instead of pip"
- "always run tests before committing"
- "ralph loop: check progress.md first"

**Let promote be smart.** It searches for related skills and figures out the best destination.

## Data Storage

| Location | Purpose |
|----------|---------|
| `.claude/CLAUDE.md` | Staged learnings + promoted instructions |
| `.claude/skills/` | Project skills (after promotion) |
| `~/.claude/skills/` | User skills (after promotion) |

## Privacy

All data stays local. Marketplace contributions only happen when you explicitly create a PR.

## License

MIT
