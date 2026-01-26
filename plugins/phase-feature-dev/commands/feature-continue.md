---
name: feature-continue
description: Continue feature development from the last checkpoint
argument-hint: "[slug]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Edit
  - Task
---

# Feature Continue Command

You are resuming a phase-isolated feature development workflow.

## Steps

1. **Identify Feature**
   - If slug argument provided, look for `.claude/features/<slug>/state.md`
   - If no slug, run: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/state-manager.sh find_active_feature`
   - If no active feature found, inform user and suggest `/feature-start`
   - If multiple features exist and no slug given, list them and ask user to specify

2. **Load State**
   - Read `.claude/features/<slug>/state.md`
   - Extract: current phase, iteration count, phase status
   - Display a brief status summary to the user

3. **Load Phase-Specific Artifacts**
   - Load ONLY the artifacts needed for the current phase:

   | Current Phase | Load These Artifacts |
   |---------------|---------------------|
   | PHASE_2_EXPLORATION | REQUIREMENTS.md |
   | PHASE_3_ARCHITECTURE | REQUIREMENTS.md, EXPLORATION.md |
   | PHASE_4_IMPLEMENTATION | ARCHITECTURE.md only |
   | PHASE_5_REVIEW | ARCHITECTURE.md (agent will examine code) |
   | PHASE_6_TESTING | ARCHITECTURE.md (agent will examine code) |
   | PHASE_7_DOCUMENTATION | REQUIREMENTS.md, ARCHITECTURE.md |

   - Do NOT load artifacts not listed above — this wastes token budget

4. **Dispatch Phase Agent**
   - Use the Task tool to launch the appropriate agent:

   | Phase | Agent |
   |-------|-------|
   | PHASE_1_REQUIREMENTS | requirements-agent |
   | PHASE_2_EXPLORATION | explorer-agent |
   | PHASE_3_ARCHITECTURE | architect-agent |
   | PHASE_4_IMPLEMENTATION | implementer-agent |
   | PHASE_5_REVIEW | reviewer-agent |
   | PHASE_6_TESTING | tester-agent |
   | PHASE_7_DOCUMENTATION | documenter-agent |

   - Include the feature slug and loaded artifact content in the agent prompt
   - The stop hook handles iteration within the phase

5. **On Phase Completion**
   - When the agent emits `<phase-complete>`, run:
     `bash ${CLAUDE_PLUGIN_ROOT}/scripts/checkpoint.sh complete_phase ".claude/features/<slug>" "<PHASE_NAME>"`
   - Inform the user of the next step:
     ```
     Phase N complete. To continue with the next phase, start a new session and run:
     /feature-continue <slug>
     ```
   - If this was the final phase (PHASE_7_DOCUMENTATION), announce feature completion

6. **On Phase Blocked**
   - When the agent emits `<phase-blocked>`, display the blocker details
   - Suggest resolution steps
   - The user can fix the blocker and run `/feature-continue` again

## Error Handling

- If state.md is missing or corrupt, inform the user and suggest `/feature-status` or starting fresh
- If the current phase is COMPLETE, inform the user the feature is done
