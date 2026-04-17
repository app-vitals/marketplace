# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code plugin marketplace** - a collection of plugins that extend Claude Code's functionality.

### Plugins

- **ralph-orchestrator** - Structured orchestration for autonomous development loops with PRD support
- **damage-control** - Defense-in-depth protection via PreToolUse hooks
- **learning-loop** - Captures corrections and discoveries, promotes to skills
- **pr-review** - Interactive PR review workflow with local drafts and parallel batch processing
- **meeting-transcripts** - Browse and read meeting transcripts captured by the mt CLI tool
- **distill** - Distill conversations into persistent context files for continuity across /clear cycles
- **dependabot-review** - AI-powered triage of Dependabot PRs with patrol-style risk assessments
- **discovery-report** - Generate dark-theme HTML discovery reports from structured interviews
- **shipwright** - Structured dev pipeline with plan sessions, task execution, autonomous dev loops, and integrated research
- **terraform** - Opinionated Terraform best practices for Claude Code
- **entropy-patrol** - Continuous code health enforcement via golden principles
- **repo-readiness** - Agent-readiness audit and bootstrapping for codebases
- **changelog-review** - Walk through git commits to review what shipped with interactive Q&A

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
│       ├── README.md
│       └── TESTING.md        # Manual test plan
```

## Conventions

- **Never use client names in public content** — no org names, repo names, or agent names in plugin examples, docs, or README content. Use `app-vitals` references instead. This repo is public; leaking client identifiers is not acceptable.

## Gotchas

- **Skills must use directory format** — `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`). Flat `.md` files in `skills/` or `.claude/skills/` are NOT registered as invocable skills and will be silently ignored by Claude Code.
- **Agent `--allowedTools` must include `Skill` and `Agent`** — when an agent spawns a Claude subprocess, missing these tools silently prevents the subprocess from invoking skills or dispatching subagents. Always include both in the allowlist if the agent needs to delegate.

## Development

This is a documentation-only repository (markdown files). No build, lint, or test commands.

When modifying plugins:
- Command files use YAML frontmatter with `name` and `description` fields
- Skill files use YAML frontmatter with `name` and `description` fields
- Templates in `assets/templates/` are used to initialize working files
- References in `references/` provide detailed guidance loaded on-demand

### Versioning

When bumping a plugin version, update all of these:
1. `plugins/<plugin-name>/.claude-plugin/plugin.json` — the `version` field
2. `README.md` (repo root) — version column in the plugin table
3. `.claude-plugin/marketplace.json` — the root `version` field (bump patch)
4. `plugins/<plugin-name>/README.md` — version in heading, if present (currently only shipwright)

Note: Plugin entries in marketplace.json do NOT have version fields — only `name`, `description`, and `source`.

See `skills/marketplace-dev/SKILL.md` for the full development guide with checklists.
