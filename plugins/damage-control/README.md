# Claude Code Damage Control

Defense-in-depth protection for Claude Code. Blocks dangerous commands and protects sensitive files via PreToolUse hooks.

**Original project by [IndyDevDan](https://github.com/disler/claude-code-damage-control)** - This plugin version is maintained by app-vitals for the marketplace.

---

## Quick Start

### Install the Plugin

```bash
/plugin install damage-control@app-vitals-marketplace
```

That's it! Protection is active immediately with sensible defaults.

### Test It Works

Try a dangerous command - it should be blocked:

```
rm -rf /tmp/test
```

You should see: `🛑 Blocked by damage-control: rm with recursive or force flags`

---

## About This Plugin

This is a marketplace plugin adaptation of [IndyDevDan's claude-code-damage-control](https://github.com/disler/claude-code-damage-control). The original project provides standalone hooks; this version packages them as a proper Claude Code marketplace plugin with enhanced discoverability, installation, and skill-based customization.

**Why Marketplace Version?**

This marketplace distribution provides:
- One-command installation via `/plugin install`
- Proper Claude Code plugin structure (plugin.json, hooks.json)
- Interactive customization skill for guided setup
- Project-specific override system
- Enhanced documentation and examples
- Maintained by app-vitals for marketplace ecosystem

**Key differences from original:**
- Marketplace plugin structure (plugin.json, hooks.json)
- One-command installation via `/plugin install`
- Interactive customization skill
- Project-specific override system

**Credit:** Core hook patterns and security logic by [IndyDevDan](https://github.com/disler).

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                   Claude Code Tool Call                              │
└─────────────────────────────────────────────────────────────────────┘
                                │
          ┌─────────────────────┼──────────────────────┬──────────────┐
          ▼                     ▼                      ▼              ▼
    ┌───────────┐         ┌───────────┐         ┌───────────┐  ┌───────────┐
    │   Bash    │         │   Read    │         │   Edit    │  │   Write   │
    │   Tool    │         │   Tool    │         │   Tool    │  │   Tool    │
    └─────┬─────┘         └─────┬─────┘         └─────┬─────┘  └─────┬─────┘
          │                     │                     │              │
          ▼                     ▼                     ▼              ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐  ┌─────────────────┐
│ bash-tool-      │   │ read-tool-      │   │ edit-tool-      │  │ write-tool-     │
│ damage-control  │   │ damage-control  │   │ damage-control  │  │ damage-control  │
│                 │   │                 │   │                 │  │                 │
│ • bashTool-     │   │ • zeroAccess-   │   │ • zeroAccess-   │  │ • zeroAccess-   │
│   Patterns      │   │   Paths         │   │   Paths         │  │   Paths         │
│ • zeroAccess-   │   │                 │   │ • readOnlyPaths │  │ • readOnlyPaths │
│   Paths         │   │                 │   │                 │  │                 │
│ • readOnlyPaths │   │                 │   │                 │  │                 │
│ • noDeletePaths │   │                 │   │                 │  │                 │
└────────┬────────┘   └────────┬────────┘   └────────┬────────┘  └────────┬────────┘
         │                     │                     │                    │
         ▼                     ▼                     ▼                    ▼
   exit 0 = allow        exit 0 = allow        exit 0 = allow      exit 0 = allow
   exit 2 = BLOCK        exit 2 = BLOCK        exit 2 = BLOCK      exit 2 = BLOCK
   JSON   = ASK
```

---

## Protection Levels

### Path Protection Matrix

| Path Type         | Read | Write | Edit | Delete | Enforced By       |
| ----------------- | ---- | ----- | ---- | ------ | ----------------- |
| `zeroAccessPaths` | ✗    | ✗     | ✗    | ✗      | Bash, Edit, Write |
| `readOnlyPaths`   | ✓    | ✗     | ✗    | ✗      | Bash, Edit, Write |
| `noDeletePaths`   | ✓    | ✓     | ✓    | ✗      | Bash only         |

### What Gets Blocked by Default

The plugin blocks dangerous operations including:

**Destructive Commands:**
- `rm -rf`, `rm --force`
- `chmod 777`, `chown -R root`
- `git reset --hard`, `git clean -fd`
- `mkfs`, `dd of=/dev/`

**Cloud Infrastructure:**
- `aws ec2 terminate-instances`
- `gcloud projects delete`
- `terraform destroy`
- `kubectl delete all --all`

**Sensitive Paths (zero-access):**
- `.env*` files
- `~/.ssh/`, `~/.aws/`, `~/.kube/`
- `*.pem`, `*.key` (private keys)
- `*.tfstate` (Terraform state files)

**Read-only Paths:**
- Lock files (`package-lock.json`, `yarn.lock`, etc.)
- System directories (`/etc/`, `/usr/`, `/bin/`)
- Shell configs (`~/.bashrc`, `~/.zshrc`)

See the full list in [`hooks/patterns.yaml`](hooks/patterns.yaml).

---

## Customizing Patterns

To customize protection for your project:

### 1. Copy the default patterns

```bash
mkdir -p .claude/hooks/damage-control
cp <plugin-path>/hooks/patterns.yaml .claude/hooks/damage-control/patterns.yaml
```

Or use the skill to help:
```
install damage control to my project
```

### 2. Edit your local patterns

```bash
# Edit .claude/hooks/damage-control/patterns.yaml
```

Example - allow checking AWS ECS container environment:
```yaml
zeroAccessPaths:
  # Original blocks all .env references
  # - "*.env"

  # More specific - only block actual .env files
  - ".env"
  - ".env.local"
  - ".env.production"
```

### 3. Your project now uses custom patterns

The hooks automatically prioritize:
1. `.claude/hooks/damage-control/patterns.yaml` (your customizations)
2. Plugin's default `patterns.yaml` (if no override exists)

### Pattern Types

**bashToolPatterns** - Block bash commands:
```yaml
bashToolPatterns:
  - pattern: '\brm\s+-[rRf]'
    reason: rm with recursive or force flags

  # Ask for confirmation instead of blocking
  - pattern: '\bDELETE\s+FROM\s+\w+\s+WHERE\b.*\bid\s*='
    reason: SQL DELETE with specific ID
    ask: true
```

**zeroAccessPaths** - No access at all:
```yaml
zeroAccessPaths:
  - "~/.ssh/"
  - "*.pem"
  - ".env*"
```

**readOnlyPaths** - Read allowed, modifications blocked:
```yaml
readOnlyPaths:
  - "package-lock.json"
  - "/etc/"
```

**noDeletePaths** - Everything except delete:
```yaml
noDeletePaths:
  - "README.md"
  - ".git/"
```

---

## Requirements

The plugin uses Python with UV for fast, zero-dependency execution.

### Install UV

**macOS/Linux:**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

---

## Damage Control Skill

The plugin includes a skill for advanced workflows like:
- Installing damage control to specific locations (global, project, personal)
- Modifying protection settings interactively
- Testing hooks
- Windows support

### Skill Triggers

| Say this...                                | And the skill will...                      |
| ------------------------------------------ | ------------------------------------------ |
| "install damage control to my project"     | Copy hooks to project-specific location    |
| "help me modify damage control"            | Guide you through adding paths or patterns |
| "test damage control"                      | Run validation tests                       |
| "add ~/.secrets to zero access paths"      | Execute directly (if you know the system)  |

---

## Troubleshooting

### Hooks not firing

1. Check `/hooks` in Claude Code to verify registration
2. Ensure UV is installed: `uv --version`
3. Check permissions: `chmod +x <plugin-path>/hooks/*.py`

### Commands still getting through

1. Check which patterns.yaml is being used (project override or plugin default)
2. Test patterns: Use the skill's test workflow
3. Run with debug: `claude --debug`

### False positives

If legitimate commands are blocked:
1. Create project override: `.claude/hooks/damage-control/patterns.yaml`
2. Remove or modify the overly-broad pattern
3. Consider using `ask: true` instead of blocking

---

## Exit Codes

| Code  | Meaning | Behavior                               |
| ----- | ------- | -------------------------------------- |
| `0`   | Allow   | Command proceeds                       |
| `0`   | Ask     | JSON output triggers permission dialog |
| `2`   | Block   | Command blocked, stderr sent to Claude |

---

## Architecture

### Plugin Structure

```
plugins/damage-control/
├── .claude-plugin/
│   └── plugin.json              # Hooks configuration
├── hooks/
│   ├── bash-tool-damage-control.py
│   ├── edit-tool-damage-control.py
│   ├── write-tool-damage-control.py
│   └── patterns.yaml            # Default patterns
├── skills/
│   └── damage-control/          # Advanced workflows
│       ├── SKILL.md
│       ├── cookbook/
│       └── hooks/               # Source for manual installs
├── images/
└── README.md
```

### Configuration Priority

```
1. .claude/hooks/damage-control/patterns.yaml   (project override)
                      ↓
2. ${CLAUDE_PLUGIN_ROOT}/hooks/patterns.yaml    (plugin default)
```

---

## Credits

- **Original Author**: [IndyDevDan](https://github.com/disler/claude-code-damage-control)
- **Plugin Maintainer**: app-vitals
- **License**: MIT

---

## Learn More

- [Original Repository](https://github.com/disler/claude-code-damage-control) - Full documentation and development guide
- [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks)
- [Tactical Agentic Coding Course](https://agenticengineer.com/tactical-agentic-coding?y=dmgctl)
- [IndyDevDan YouTube](https://www.youtube.com/@indydevdan)
