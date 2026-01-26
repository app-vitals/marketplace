---
name: feature-reset
description: Reset a phase to redo it (preserves prior phase artifacts)
argument-hint: <slug> <phase>
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
---

# Feature Reset Command

Reset a specific phase to re-do it while preserving prior phase artifacts.

## Arguments

- **slug** (required): Feature slug identifying the feature
- **phase** (required): Phase number (1-7) or name (requirements, exploration, architecture, implementation, review, testing, documentation)

## Steps

1. **Parse Phase Argument**
   - Accept either number or name:
     - `1` or `requirements` → PHASE_1_REQUIREMENTS
     - `2` or `exploration` → PHASE_2_EXPLORATION
     - `3` or `architecture` → PHASE_3_ARCHITECTURE
     - `4` or `implementation` → PHASE_4_IMPLEMENTATION
     - `5` or `review` → PHASE_5_REVIEW
     - `6` or `testing` → PHASE_6_TESTING
     - `7` or `documentation` → PHASE_7_DOCUMENTATION
   - If invalid, show usage and valid options

2. **Validate**
   - Check `.claude/features/<slug>/state.md` exists
   - Read current state to confirm what will be reset

3. **Confirm with User**
   - Show what will happen:
     ```
     This will reset Phase <N> (<name>) and require re-running phases <N> through 7.
     Existing artifact will be archived to .claude/features/<slug>/archive/.
     Continue?
     ```
   - Wait for explicit confirmation before proceeding

4. **Execute Reset**
   - Run: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/checkpoint.sh reset_phase ".claude/features/<slug>" "<PHASE_NAME>"`
   - This archives the existing artifact and resets the phase status

5. **Confirm Completion**
   - Show updated status
   - Inform user:
     ```
     Phase <N> (<name>) has been reset.
     To re-run this phase, start a new session and run:
     /feature-continue <slug>
     ```

## Error Handling

- If slug not found, list available features
- If phase not found, show valid phase numbers/names
- If user declines confirmation, exit without changes
