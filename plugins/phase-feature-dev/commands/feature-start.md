---
name: feature-start
description: Start a new feature development workflow with phase-isolated sessions
argument-hint: <description>
allowed-tools:
  - Bash
  - Write
  - Read
  - AskUserQuestion
  - Task
---

# Feature Start Command

You are initiating a new phase-isolated feature development workflow.

## Steps

1. **Generate Feature Slug**
   - Take the description argument and convert it to a URL-safe slug
   - Replace spaces with hyphens, lowercase, remove special characters
   - Example: "Add Prometheus query caching" → `add-prometheus-query-caching`

2. **Create Feature Directory**
   - Run: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/checkpoint.sh init_feature "<slug>" "<description>"`
   - This creates `.claude/features/<slug>/` with an initialized `state.md`
   - If the feature already exists, inform the user and suggest `/feature-continue <slug>`

3. **Confirm with User**
   - Show the user: Feature name, slug, and that Phase 1 (Requirements) will begin
   - Ask if they want to proceed

4. **Dispatch Requirements Agent**
   - Use the Task tool to launch the `requirements-agent` with:
     ```
     Gather requirements for the feature at .claude/features/<slug>/.
     Read state.md for context. Write REQUIREMENTS.md when complete.
     Output <phase-complete>PHASE_1_REQUIREMENTS</phase-complete> when done.
     ```
   - The stop hook will keep the agent iterating until requirements are complete or the iteration limit (10) is reached

5. **On Completion**
   - When the requirements agent finishes (either via `<phase-complete>` or iteration limit):
   - Run: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/checkpoint.sh complete_phase ".claude/features/<slug>" "PHASE_1_REQUIREMENTS"`
   - Inform the user:
     ```
     Requirements phase complete. Artifacts saved to .claude/features/<slug>/.
     To continue with codebase exploration, start a new session and run:
     /feature-continue <slug>
     ```

## Error Handling

- If `init_feature` fails (directory already exists), suggest `/feature-continue` or `/feature-reset`
- If the user cancels during confirmation, exit cleanly without creating anything
