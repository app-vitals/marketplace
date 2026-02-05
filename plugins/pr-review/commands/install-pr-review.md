---
name: install-pr-review
description: Install pr-review CLI tools to ~/.local/bin
allowed-tools:
  - Bash
---

# Install pr-review CLI Tools

Install the `review-pr` CLI wrapper to `~/.local/bin` for quick terminal access.

## Process

1. **Check prerequisites**:
   ```bash
   command -v claude && echo "Claude: OK" || echo "Claude: NOT FOUND"
   command -v gh && echo "gh CLI: OK" || echo "gh CLI: NOT FOUND"
   ```

2. **Create ~/.local/bin if needed**:
   ```bash
   mkdir -p ~/.local/bin
   ```

3. **Find the plugin scripts directory**:
   Use `${CLAUDE_PLUGIN_ROOT}` to locate the scripts folder.

4. **Symlink the review-pr wrapper**:
   ```bash
   ln -sf "${CLAUDE_PLUGIN_ROOT}/scripts/review-pr" ~/.local/bin/review-pr
   ```

5. **Verify installation**:
   ```bash
   ls -la ~/.local/bin/review-pr
   ```

6. **Check PATH**:
   ```bash
   echo $PATH | grep -q "$HOME/.local/bin" && echo "PATH: OK" || echo "Note: Add ~/.local/bin to your PATH"
   ```

7. **Show success message**:
   ```
   Installed! Usage:
     review-pr 123
     review-pr https://github.com/owner/repo/pull/123
   ```

If `~/.local/bin` is not in PATH, remind user to add to their shell config:
```bash
export PATH="$HOME/.local/bin:$PATH"
```
