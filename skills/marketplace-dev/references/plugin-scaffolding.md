# Plugin Scaffolding Templates

Use these templates when creating a new plugin from scratch.

## Directory Structure

```
plugins/<name>/
├── .claude-plugin/
│   └── plugin.json          # Required: plugin manifest
├── commands/                # Optional: slash commands (*.md)
├── skills/                  # Optional: skill definitions
│   └── <skill-name>/
│       ├── SKILL.md
│       ├── references/      # On-demand guidance docs
│       └── assets/
│           └── templates/   # Output templates
├── hooks/                   # Optional: hook implementations
│   ├── hooks.json           # Hook configuration (if not in plugin.json)
│   └── <hook-impl>.sh       # Shell or Python scripts
├── agents/                  # Optional: agent definitions (*.md)
├── scripts/                 # Optional: utility scripts
├── README.md                # Required: plugin documentation
└── TESTING.md               # Recommended: manual test plan
```

## plugin.json Template

```json
{
  "name": "<plugin-name>",
  "version": "0.1.0",
  "description": "<one-line description of what the plugin does>",
  "author": {
    "name": "app-vitals",
    "email": "dave@app-vitals.com"
  },
  "keywords": ["claude-code", "<relevant>", "<keywords>"],
  "homepage": "https://github.com/app-vitals/marketplace",
  "repository": "https://github.com/app-vitals/marketplace",
  "license": "MIT"
}
```

**Notes**:
- `name` must match the directory name, kebab-case
- Start at `0.1.0` for new plugins (use `1.0.0` if shipping with stable behavior)
- `description` should be concise — the long-form description goes in README.md
- Add a `hooks` section only if the plugin has hooks configured in plugin.json (vs hooks.json)

## marketplace.json Entry

Add to the `plugins` array in `.claude-plugin/marketplace.json`:

```json
{
  "name": "<plugin-name>",
  "description": "<one-line description matching plugin.json>",
  "source": "./plugins/<plugin-name>"
}
```

**Do not add** a version field to the entry. Only `name`, `description`, and `source`.

## Root README Table Row

Add to the plugin table in `README.md`:

```markdown
| [<plugin-name>](plugins/<plugin-name>/README.md) | 0.1.0 | <short description> |
```

## Root README Install Section

Add below the table:

```markdown
### <plugin-name>

\```
/plugin install <plugin-name>@app-vitals/marketplace
\```

`/<command-1>` · `/<command-2>`
```

If the plugin has no commands (hooks/skills only):

```markdown
No commands — <hooks activate automatically on install / skill activates automatically when ...>.
```

## CLAUDE.md Plugins List Entry

Add to the Plugins list:

```markdown
- **<plugin-name>** - <one-line description>
```

## Plugin README.md Template

```markdown
# <Plugin Name>

<2-3 sentence description of what the plugin does and why.>

## Installation

\```
/plugin install <plugin-name>@app-vitals/marketplace
\```

## Commands

### /<command-name>

<what the command does>

**Usage:**
\```
/<command-name> [arguments]
\```

## How It Works

<brief explanation of the plugin's behavior, hooks, or skills>
```

## TESTING.md Template

```markdown
# Testing: <plugin-name>

Manual test plan for <plugin-name>.

---

## <Feature/Command> Tests

### Test 1: <Scenario Name>

**Setup:** <prerequisites, files to create, state to configure>

**Command:** `/<command-name> [args]`

**Verify:**
- [ ] <expected behavior 1>
- [ ] <expected behavior 2>
- [ ] <expected output or file state>

---

### Test 2: <Next Scenario>

**Setup:** <prerequisites>

**Command:** `/<command-name> [args]`

**Verify:**
- [ ] <expected behavior>

---

## Regression Checklist

Before shipping:
- [ ] All test scenarios pass
- [ ] Plugin installs cleanly via `/plugin install`
- [ ] No conflicts with other marketplace plugins
- [ ] Version bumped in all required locations
```
