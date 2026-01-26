---
name: feature-status
description: Display feature development progress and status
argument-hint: "[slug]"
allowed-tools:
  - Read
  - Glob
---

# Feature Status Command

Display the current status of feature development.

## Steps

1. **Find Features**
   - If slug provided, read `.claude/features/<slug>/state.md`
   - If no slug, scan `.claude/features/*/state.md` for all features
   - If no features found, inform user: "No features in progress. Run `/feature-start` to begin."

2. **Parse State**
   - For each feature, extract from state.md:
     - Feature name and description
     - Overall status (IN_PROGRESS, BLOCKED, COMPLETE)
     - Current phase name and iteration count
     - Each phase's completion status

3. **Display Progress Table**
   - Format output as:

   ```
   ### Feature: <name>
   **Status:** <status>
   **Current Phase:** <phase name> (iteration <n>/<max>)

   | Phase | Status | Iterations |
   |-------|--------|------------|
   | Requirements | ✓ | 3/10 |
   | Exploration | ✓ | 7/10 |
   | Architecture | ⏳ | 4/15 |
   | Implementation | ○ | --/25 |
   | Review | ○ | --/10 |
   | Testing | ○ | --/15 |
   | Documentation | ○ | --/5 |

   **Next Step:** `/feature-continue <slug>`
   ```

   - Use ✓ for completed, ⏳ for in-progress, ○ for pending
   - Show iteration counts where available

4. **If Multiple Features**
   - Show a summary table first, then details for each
   - Highlight which feature is currently active (IN_PROGRESS)
