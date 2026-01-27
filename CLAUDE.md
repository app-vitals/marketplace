# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code plugin marketplace** - a collection of plugins that extend Claude Code's functionality.

## Architecture

### Marketplace Structure

Plugins live in the `plugins/` directory:

```
marketplace/
├── .claude-plugin/
│   └── marketplace.json      # Marketplace manifest with plugin list
├── plugins/
│   └── plugin-name/
│       ├── .claude-plugin/
│       │   └── plugin.json   # Plugin manifest (name, version, description, hooks)
│       ├── commands/         # Slash commands (*.md files with YAML frontmatter)
│       ├── hooks/            # Hook implementations (*.md files)
│       ├── skills/           # Complex functionality with references/templates
│       │   └── skill-name/
│       │       ├── SKILL.md  # Skill definition with YAML frontmatter
│       │       ├── assets/   # Templates, configs
│       │       └── references/
│       └── README.md
```

## Development

This is a documentation-only repository (markdown files). No build, lint, or test commands.

When modifying plugins:
- Command files use YAML frontmatter with `name` and `description` fields
- Skill files use YAML frontmatter with `name` and `description` fields
- Templates in `assets/templates/` are used to initialize working files
- References in `references/` provide detailed guidance loaded on-demand

### Versioning

When bumping a plugin version:
1. Update `plugins/<plugin-name>/.claude-plugin/plugin.json` (version field)
2. Update `.claude-plugin/marketplace.json` (both root version and plugin entry version)

Keep all version numbers in sync.
