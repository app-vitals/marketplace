# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code plugin marketplace** - a collection of plugins that extend Claude Code's functionality. Currently contains the `ralph-orchestrator` plugin.

## Architecture

### Marketplace Structure

Plugins live in the `plugins/` directory:

```
marketplace/
├── plugins/
│   └── plugin-name/
│       ├── .claude-plugin/
│       │   └── plugin.json   # Plugin manifest (name, version, description)
│       ├── commands/         # Slash commands (*.md files with YAML frontmatter)
│       ├── skills/           # Complex functionality with references/templates
│       │   └── skill-name/
│       │       ├── SKILL.md  # Skill definition with YAML frontmatter
│       │       ├── assets/   # Templates, configs
│       │       └── references/
│       └── README.md
```

### Ralph Orchestrator Plugin

Wraps the official `ralph-loop` plugin to add structured scaffolding for autonomous development loops:

**Commands:**
- `/prd <task-name>` - Create PRD for complex multi-feature work
- `/ralph-freeform <task-name>` - Create plan for simpler single-goal tasks
- `/ralph <task-name>` - Start orchestrated loop (detects PRD vs plan vs raw freeform)

**Working Files Location:** `.claude/ralph/<task-name>/`
- `progress.md` - Append-only learnings, iteration history
- `AGENTS.md` - Task-specific patterns
- `prd.json` / `plan.json` - Machine-readable status tracking
- `PRD.md` / `PLAN.md` - Human-readable documents

**Key Concepts:**
- Stories/phases should be completable in 1-3 iterations
- 3-attempt escape hatch rule prevents infinite loops
- TDD workflow: write test → fail → implement → pass → commit
- Completion promises: `<promise>ALL STORIES PASS</promise>`, `<promise>ALL PHASES COMPLETE</promise>`, or `<promise>TASK COMPLETE</promise>`

## Development

This is a documentation-only repository (markdown files). No build, lint, or test commands.

When modifying plugins:
- Command files use YAML frontmatter with `name` and `description` fields
- Skill files use YAML frontmatter with `name` and `description` fields
- Templates in `assets/templates/` are used to initialize working files
- References in `references/` provide detailed guidance loaded on-demand

### Versioning

When bumping a plugin version, also bump the marketplace version in `.claude-plugin/marketplace.json` to keep them in sync.
