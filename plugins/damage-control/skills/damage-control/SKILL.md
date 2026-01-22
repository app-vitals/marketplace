---
name: damage-control-customizer
description: Customize damage-control protection patterns for your project. Creates local pattern overrides based on project context. Use when user wants to adjust protection rules, allow specific commands, or customize path protection for their project needs.
---

# Damage Control Customizer

Help users create project-specific pattern overrides that balance security with their workflow needs.

## Overview

The damage-control plugin works immediately with default patterns. This skill helps users customize those patterns when:
- Legitimate commands are being blocked (false positives)
- Project uses specific tools that need different rules
- Sensitive project files need additional protection

## How Override Works

**Pattern Priority:**
1. `.claude/hooks/damage-control/patterns.yaml` (project override - this skill creates this)
2. Plugin's default `patterns.yaml` (fallback)

Hooks automatically check for project override first, making customization safe and reversible.

---

## Workflow

### Step 1: Check Current State

**Check if override already exists:**
```bash
ls -la .claude/hooks/damage-control/patterns.yaml
```

**If exists:**
- Tell user: "You already have custom patterns at `.claude/hooks/damage-control/patterns.yaml`"
- Ask: "Would you like to edit the existing file or start fresh?"
  - Edit → Skip to Step 3
  - Fresh → Continue to Step 2

**If not exists:**
- Continue to Step 2

### Step 2: Create Override File

**Get plugin default location:**
- Need to find: `${CLAUDE_PLUGIN_ROOT}/hooks/patterns.yaml`
- If you can't determine plugin root, instruct user:
  ```bash
  # Find the plugin
  /plugin list

  # Copy patterns (user will need to substitute actual path)
  mkdir -p .claude/hooks/damage-control
  cp <damage-control-plugin-path>/hooks/patterns.yaml .claude/hooks/damage-control/patterns.yaml
  ```

**If you can determine plugin root, copy directly:**
```bash
mkdir -p .claude/hooks/damage-control
cp ${CLAUDE_PLUGIN_ROOT}/hooks/patterns.yaml .claude/hooks/damage-control/patterns.yaml
```

### Step 3: Analyze Project Context

**Scan project to understand what might need customization:**

1. **Check package.json / requirements.txt / Gemfile** - What tools/frameworks are used?
2. **Check .gitignore** - What files are already ignored?
3. **Check for AWS/cloud configs** - Does project use cloud services?
4. **Check for databases** - SQLite, Postgres, MongoDB files?

**Common patterns by project type:**

**AWS/Cloud Projects:**
- May want to allow: `aws ecs describe-tasks --query 'tasks[0].containers[0].environment'`
- Problem: Default `*.env` pattern blocks this
- Solution: Make `zeroAccessPaths` more specific

**Database Projects:**
- May want to allow: Specific DELETE commands with WHERE clauses
- Problem: Blanket DELETE blocking is too aggressive
- Solution: Move some patterns to `ask: true`

**Monorepo/Build Systems:**
- May want to allow: Recursive operations in specific directories
- Problem: Blanket `rm -rf` blocking prevents cleanup
- Solution: Use more specific path patterns

### Step 4: Suggest Customizations

Based on project analysis, suggest specific edits to the user.

**Example suggestions:**

"I noticed you're using AWS ECS. The default patterns block all `*.env` references, which might interfere with `aws ecs` commands that query environment variables. Consider this change:"

```yaml
# Before (too broad):
zeroAccessPaths:
  - "*.env"

# After (more specific):
zeroAccessPaths:
  - ".env"
  - ".env.local"
  - ".env.production"
  - "**/*.env"  # Still blocks .env files in subdirectories
```

"I see you have a SQLite database. Consider changing DELETE protection from blocking to asking:"

```yaml
# Before (blocks all):
bashToolPatterns:
  - pattern: 'DELETE\s+FROM\s+\w+\s*;'
    reason: DELETE without WHERE clause

# After (ask for confirmation):
bashToolPatterns:
  - pattern: 'DELETE\s+FROM\s+\w+\s+WHERE\b'
    reason: DELETE with WHERE clause
    ask: true
```

### Step 5: Guide User Through Edits

**Present clear steps:**

1. Open the file: `.claude/hooks/damage-control/patterns.yaml`
2. Find the section: `zeroAccessPaths` (or relevant section)
3. Replace: `[old pattern]`
4. With: `[new pattern]`
5. Save and test

### Step 6: Test Changes

**Test patterns by calling hooks directly:**

```bash
# Test bash hook blocks dangerous command (expect exit code 2)
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | \
  uv run ${CLAUDE_PLUGIN_ROOT}/hooks/bash-tool-damage-control.py
echo "Exit code: $?"  # Should be 2 (blocked)

# Test bash hook allows safe command (expect exit code 0)
echo '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' | \
  uv run ${CLAUDE_PLUGIN_ROOT}/hooks/bash-tool-damage-control.py
echo "Exit code: $?"  # Should be 0 (allowed)

# Test edit hook blocks zero-access path (expect exit code 2)
echo '{"tool_name":"Edit","tool_input":{"file_path":"~/.ssh/id_rsa"}}' | \
  uv run ${CLAUDE_PLUGIN_ROOT}/hooks/edit-tool-damage-control.py
echo "Exit code: $?"  # Should be 2 (blocked)

# Test write hook blocks zero-access path (expect exit code 2)
echo '{"tool_name":"Write","tool_input":{"file_path":".env"}}' | \
  uv run ${CLAUDE_PLUGIN_ROOT}/hooks/write-tool-damage-control.py
echo "Exit code: $?"  # Should be 2 (blocked)
```

**Exit codes:**
- `0` = Allowed (command proceeds)
- `2` = Blocked (error message in stderr)

**Test after each change:**
- Edit one pattern → Test with hook → Verify exit code
- Iterate until working correctly
- **Important**: Hook scripts only validate patterns - they don't execute commands

### Step 7: Iterate

Repeat Steps 5-6 for each pattern that needs adjustment:
- Make one change at a time
- Test immediately with the hook script
- Verify expected exit code
- Move to next change

**Hook testing is safe** - hooks validate patterns but don't execute commands

---

## Pattern Reference

### bashToolPatterns

Block or ask for confirmation on bash commands:

```yaml
bashToolPatterns:
  # Block entirely (default)
  - pattern: '\brm\s+-[rRf]'
    reason: rm with recursive or force flags

  # Ask for confirmation
  - pattern: '\bgit\s+push\s+\S+\s+--delete'
    reason: Deletes remote branch
    ask: true
```

### Path Protection Levels

**zeroAccessPaths** - No access at all (secrets/credentials):
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
  - "*.lock"
```

**noDeletePaths** - All operations except delete:
```yaml
noDeletePaths:
  - "README.md"
  - ".git/"
  - "CLAUDE.md"
```

### Glob Patterns

Supports:
- `*.ext` - Files with extension
- `prefix*` - Files starting with prefix
- `.env*` - Files starting with .env
- `**/*.ext` - Recursive pattern

---

## Common Customizations

### Allow AWS CLI Environment Queries

**Problem:** `aws ecs describe-tasks --query 'tasks[0].containers[0].environment'` blocked

**Solution:**
```yaml
zeroAccessPaths:
  # Remove: "*.env"
  # Add more specific patterns:
  - ".env"
  - ".env.local"
  - ".env.production"
```

### Allow Specific Directory Cleanup

**Problem:** `rm -rf build/` blocked by blanket rm -rf protection

**Solution:**
```yaml
bashToolPatterns:
  # Keep general protection
  - pattern: '\brm\s+-[rRf].*(/|~|\$HOME|/usr|/etc)'
    reason: rm -rf on dangerous paths

  # Remove: '\brm\s+-[rRf]'  (too broad)
```

### Make Database Operations Ask Instead of Block

**Problem:** All DELETE commands blocked, even safe ones

**Solution:**
```yaml
bashToolPatterns:
  # Block dangerous (no WHERE)
  - pattern: 'DELETE\s+FROM\s+\w+\s*;'
    reason: DELETE without WHERE clause

  # Ask for safe (with WHERE)
  - pattern: 'DELETE\s+FROM\s+\w+\s+WHERE\b'
    reason: DELETE with WHERE clause
    ask: true
```

---

## Recovery

If customizations break protection:

**Restore defaults:**
```bash
rm .claude/hooks/damage-control/patterns.yaml
# Hooks will fall back to plugin default
```

**Compare with default:**
```bash
diff .claude/hooks/damage-control/patterns.yaml <plugin-path>/hooks/patterns.yaml
```

---

## Tips

- **Start conservative**: Remove one pattern at a time
- **Test immediately**: Verify change works as expected
- **Keep git history**: Commit working configurations
- **Document changes**: Add comments explaining why patterns were customized
- **Use ask instead of remove**: When unsure, change `pattern` to include `ask: true` rather than removing it entirely

---

## Related

- Plugin default patterns: `<plugin-path>/hooks/patterns.yaml`
- Override location: `.claude/hooks/damage-control/patterns.yaml`
- Original documentation: https://github.com/disler/claude-code-damage-control
