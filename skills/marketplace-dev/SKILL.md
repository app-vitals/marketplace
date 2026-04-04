---
name: marketplace-dev
description: >
  This skill MUST activate when creating, modifying, or reviewing any plugin
  in this marketplace repository. Triggers on: editing files under plugins/,
  creating new plugins, bumping versions, modifying plugin.json or
  marketplace.json, adding commands/skills/agents/hooks, editing TESTING.md,
  reviewing or creating pull requests that touch the plugins/ directory, or
  when user mentions "new plugin", "version bump", "release", "add command",
  "add skill", "add hook", "add agent", "marketplace update", or "plugin
  checklist". This skill prevents version drift and enforces structural
  conventions across all marketplace plugins.
---

# Marketplace Development Guide

This skill encodes the conventions and checklists for working with plugins in the app-vitals marketplace. Follow it to prevent version drift and maintain consistency.

## When This Activates

- Creating a new plugin
- Bumping a plugin version (new feature, bug fix, breaking change)
- Adding or modifying commands, skills, agents, or hooks
- Editing `plugin.json` or `marketplace.json`
- Updating plugin descriptions or README content
- Creating or reviewing PRs that touch `plugins/`
- Adding a plugin to or removing one from the marketplace

---

## Version Sync Protocol

**This is the most important section.** Version drift across files is the #1 source of mistakes in this repo.

### Locations to Update When Bumping a Plugin Version

Every version bump requires updating **all three** of these:

| # | File | What to Change |
|---|------|----------------|
| 1 | `plugins/<name>/.claude-plugin/plugin.json` | `"version"` field |
| 2 | `README.md` (repo root) | Version column in the plugin table |
| 3 | `.claude-plugin/marketplace.json` | Root `"version"` field (bump patch) |

**Conditionally** update this fourth location:

| # | File | When |
|---|------|------|
| 4 | `plugins/<name>/README.md` | Only if the plugin has a version in its heading (e.g., `# Shipwright v1.4.0`). Currently only shipwright does this. |

### What NOT to Update

Plugin entries in `marketplace.json` do **NOT** have version fields. They only have `name`, `description`, and `source`. Do not try to add or update a version there.

### Semver Guidance

| Change Type | Bump | Examples |
|-------------|------|----------|
| Bug fix, doc correction | Patch (0.1.0 → 0.1.1) | Fix typo in command, correct hook behavior |
| New command, skill, agent, or hook | Minor (0.1.0 → 0.2.0) | Add `/audit` command, add new skill |
| Breaking change to existing behavior | Major (0.2.0 → 1.0.0) | Rename command, change hook matcher, restructure skill |

### Marketplace Root Version

Bump the **root** `version` in `.claude-plugin/marketplace.json` whenever any plugin version changes. Use patch bumps (2.7.0 → 2.8.0 for new plugins, 2.7.0 → 2.7.1 for plugin patches). This signals to consumers that the marketplace has been updated.

For the full step-by-step checklist with verification commands, see `references/version-sync-checklist.md`.

---

## New Plugin Checklist

When creating a new plugin from scratch, complete every step:

1. **Create directory**: `plugins/<name>/` using kebab-case
2. **Create plugin manifest**: `plugins/<name>/.claude-plugin/plugin.json`
   - Use the canonical schema from `references/plugin-scaffolding.md`
   - Standardized author: `{ "name": "app-vitals", "email": "dave@app-vitals.com" }`
3. **Add at least one component**: command, skill, hook, or agent
4. **Create plugin README**: `plugins/<name>/README.md`
5. **Create test plan**: `plugins/<name>/TESTING.md` with smoke test scenarios
6. **Add marketplace entry**: append to `plugins` array in `.claude-plugin/marketplace.json`
   ```json
   {
     "name": "<name>",
     "description": "<one-line description>",
     "source": "./plugins/<name>"
   }
   ```
7. **Add README table row**: add a row to the plugin table in root `README.md`
8. **Add README install section**: add install command and command listing under the table
9. **Add CLAUDE.md entry**: add one-liner to the Plugins list in `CLAUDE.md`
10. **Bump marketplace version**: bump root `version` in `.claude-plugin/marketplace.json`

For templates of each file, see `references/plugin-scaffolding.md`.

---

## Plugin Modification Checklist

When modifying an existing plugin:

### Adding a New Component (command, skill, agent, hook)

1. Create the component file following conventions (see `references/frontmatter-schemas.md`)
2. If the plugin has a TESTING.md, add test scenarios for the new component
3. Update `plugins/<name>/README.md` if it lists available commands
4. Update root `README.md` command listing for this plugin (if applicable)
5. Bump the plugin version (minor bump) — follow the Version Sync Protocol above

### Modifying Existing Behavior

1. Make the change
2. Update TESTING.md if test scenarios are affected
3. Bump the plugin version (patch or minor) — follow the Version Sync Protocol above

### Changing a Plugin Description

If you change the description in `plugin.json`, also sync it to:
- The `description` field in the marketplace.json plugin entry
- The description column in the root README table
- The one-liner in CLAUDE.md Plugins list

---

## Component Conventions

### Commands (`commands/*.md`)

```yaml
---
description: Short action-oriented description     # Required
argument-hint: <required-arg> [optional-arg]        # Optional
allowed-tools: [Read, Glob, Grep, Bash]             # Optional
---
```

- Filename = command name + `.md` (e.g., `plan-session.md` → `/plan-session`)
- Kebab-case filenames only
- For new work, consider the `skills/<name>/SKILL.md` layout instead (preferred by Anthropic)

### Skills (`skills/<name>/SKILL.md`)

```yaml
---
name: skill-name                                    # Required, matches directory name
description: >                                      # Required, ~100 words
  When to trigger and what it does...
---
```

- Directory name = skill name, kebab-case
- Use `references/` subdirectory for detailed guidance loaded on-demand
- Use `assets/templates/` for output templates
- Keep SKILL.md under 500 lines; split to references if exceeding

### Agents (`agents/*.md`)

```yaml
---
name: agent-name                                    # Required
description: >                                      # Required
  When to use this agent...
model: sonnet                                       # Optional (sonnet, opus, haiku)
tools:                                              # Required
  - Read
  - Edit
  - Grep
---
```

### Hooks

Hooks can be configured in `plugin.json` directly (simple cases) or in `hooks/hooks.json` (complex multi-matcher setups). Use shell scripts (`.sh`) or Python (`.py`) for implementation.

For complete schemas and examples, see `references/frontmatter-schemas.md`.

---

## Naming & Consistency Standards

### Plugin Names
- Kebab-case only: `my-plugin`, not `myPlugin` or `my_plugin`
- Directory name must match `name` field in plugin.json

### Author Field (Standardized)
```json
"author": {
  "name": "app-vitals",
  "email": "dave@app-vitals.com"
}
```
Do not use `"App Vitals"` (capitalized) or `"url"` instead of `"email"`.

### Repository and Homepage
```json
"homepage": "https://github.com/app-vitals/marketplace",
"repository": "https://github.com/app-vitals/marketplace"
```
Do not use `app-vitals/app-vitals-marketplace`.

### License
All plugins use `"license": "MIT"`.

---

## Description Sync Points

A plugin's description appears in multiple places. When changing it, update all:

| Location | Format |
|----------|--------|
| `plugins/<name>/.claude-plugin/plugin.json` | `"description"` field (canonical source) |
| `.claude-plugin/marketplace.json` | `"description"` in plugin entry |
| `README.md` (root) | Description column in plugin table |
| `CLAUDE.md` | One-liner in Plugins list |
| `plugins/<name>/README.md` | Opening paragraph (may be longer form) |

---

## References

Load these for detailed guidance when needed:

- **`references/version-sync-checklist.md`** — Step-by-step version bump with verification commands
- **`references/plugin-scaffolding.md`** — Templates for new plugin files (plugin.json, README, TESTING.md)
- **`references/frontmatter-schemas.md`** — Complete YAML frontmatter schemas for all component types
