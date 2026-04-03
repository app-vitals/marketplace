# Version Sync Checklist

Step-by-step process for bumping a plugin version without missing any sync points.

## Pre-Bump: Verify Current State

Before bumping, confirm the current version is consistent. Read the current version from plugin.json, then verify it matches the root README table:

```bash
# Check current version in plugin.json
cat plugins/<name>/.claude-plugin/plugin.json | grep '"version"'

# Check version in root README table
grep '<name>' README.md
```

If they're already out of sync, fix the drift first before bumping.

## Step 1: Decide the New Version

| What changed | Bump type | Example |
|---|---|---|
| Bug fix, typo, doc fix | Patch | 1.2.0 → 1.2.1 |
| New command, skill, agent, hook | Minor | 1.2.0 → 1.3.0 |
| Breaking change to behavior | Major | 1.2.0 → 2.0.0 |

## Step 2: Update Plugin Manifest

**File**: `plugins/<name>/.claude-plugin/plugin.json`

Change the `"version"` field to the new version.

## Step 3: Update Root README Table

**File**: `README.md`

Find the plugin's row in the table (lines 15-27) and update the version column.

```markdown
| [<name>](plugins/<name>/README.md) | X.Y.Z | Description |
```

## Step 4: Bump Marketplace Root Version

**File**: `.claude-plugin/marketplace.json`

Bump the root `"version"` field. Use patch bump for plugin patches, minor bump for new plugins or features.

**Do NOT** try to add a version to the plugin entry — entries only have `name`, `description`, `source`.

## Step 5: Update Plugin README (Conditional)

**File**: `plugins/<name>/README.md`

Only if the plugin has a version in its heading (e.g., `# Shipwright v1.4.0`). Currently only shipwright uses this pattern. If the heading has no version, skip this step.

## Post-Bump: Verification

After making all changes, verify consistency:

```bash
# Extract version from plugin.json
grep '"version"' plugins/<name>/.claude-plugin/plugin.json

# Check it matches README table
grep '<name>' README.md

# Confirm marketplace root version was bumped
grep '"version"' .claude-plugin/marketplace.json
```

All three should reflect the updates.

## Concrete Example

Bumping `shipwright` from 1.4.0 to 1.5.0 (added a new command):

1. **plugin.json**: Change `"version": "1.4.0"` → `"version": "1.5.0"`
   - File: `plugins/shipwright/.claude-plugin/plugin.json`

2. **Root README table**: Change `| 1.4.0 |` → `| 1.5.0 |`
   - File: `README.md`, shipwright row

3. **Marketplace version**: Change `"version": "2.7.0"` → `"version": "2.8.0"`
   - File: `.claude-plugin/marketplace.json`, root version field

4. **Plugin README heading**: Change `# Shipwright v1.4.0` → `# Shipwright v1.5.0`
   - File: `plugins/shipwright/README.md` (shipwright is the exception that has this)
