---
name: uninstall-pr-review
description: Remove pr-review CLI tools from ~/.local/bin
allowed-tools:
  - Bash
---

# Uninstall pr-review CLI Tools

Remove the `review-pr` CLI wrapper from `~/.local/bin`.

## Process

1. **Check if installed**:
   ```bash
   ls -la ~/.local/bin/review-pr 2>/dev/null
   ```

2. **Remove symlink**:
   ```bash
   rm ~/.local/bin/review-pr
   ```

3. **Confirm removal**:
   ```
   Removed review-pr from ~/.local/bin
   ```

If not installed, inform user:
```
review-pr is not installed in ~/.local/bin
```
