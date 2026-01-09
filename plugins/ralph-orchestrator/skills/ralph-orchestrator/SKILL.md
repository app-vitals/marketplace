---
name: ralph-orchestrator
description: Build structured prompts for Ralph loops with TDD guidance, progress tracking, verification steps, and escape hatches. Invoke when starting a Ralph-based development task, creating orchestrated iteration loops, or converting PRDs to executable Ralph prompts. Wraps the official ralph-loop plugin to maximize loop success rates through careful prompt engineering and persistent state management.
---

# Ralph Orchestrator

Build structured, scaffolded prompts for Ralph loops that maximize success rates through:
- **Progress tracking**: Persistent learnings that survive iterations
- **Context health**: When to commit, summarize, or archive
- **TDD workflow**: Test-first development patterns
- **Escape hatches**: Recovery when stuck
- **Verification**: Automatic and manual verification steps

## Core Concept

Ralph loops succeed when Claude has:
1. **Clear completion criteria** - Unambiguous signal for when to output the completion promise
2. **Progress visibility** - Ability to see what worked/failed in previous iterations
3. **Incremental goals** - Small, achievable steps that build momentum
4. **Recovery paths** - What to do when stuck

This skill builds prompts that embed all these elements.

## How Ralph Works

The official `ralph-loop` plugin creates a self-referential feedback loop:
1. Your prompt is fed to Claude
2. Claude works on the task
3. Claude tries to exit
4. Stop hook intercepts exit and re-feeds the SAME prompt
5. Repeat until completion promise is detected or max iterations reached

**Key insight**: The prompt never changes between iterations. Claude's "memory" comes from:
- Files on disk (progress.md, AGENTS.md, prd.json, your code)
- Git history
- Test results

This skill builds prompts that leverage these persistence mechanisms.

---

## Workflow

### Phase 1: Understand the Input

Determine input mode from the invocation context:

**PRD Mode** (if `.claude/ralph/<task-name>/prd.json` exists):
- Read the prd.json file
- Extract stories, success criteria, verification method
- Identify which stories are already passing (`"passes": true`)
- Determine next story to work on
- Completion promise: `<promise>ALL STORIES PASS</promise>`

**Plan Mode** (if `.claude/ralph/<task-name>/plan.json` exists):
- Read the plan.json file
- Extract phases, goal, success criteria, verification method
- Identify which phases are already complete (`"complete": true`)
- Determine next phase to work on
- Completion promise: `<promise>ALL PHASES COMPLETE</promise>`

**Raw Freeform Mode** (if neither PRD nor plan exists):
- Parse the provided prompt text
- Infer success criteria from the description
- Create implicit single-phase structure
- Completion promise: `<promise>TASK COMPLETE</promise>`

### Phase 2: Initialize Working Files

Ensure working files exist in `.claude/ralph/<task-name>/`:

**progress.md** - Create from template if not exists:
- Read `assets/templates/progress_template.md`
- Fill in task name, timestamp, mode, first story ID
- Write to `.claude/ralph/<task-name>/progress.md`

**AGENTS.md** - Create from template if not exists:
- Read `assets/templates/agents_template.md`
- Fill in task name, timestamp, problem statement
- Write to `.claude/ralph/<task-name>/AGENTS.md`

### Phase 3: Build the Master Prompt

The master prompt is fed to Claude each iteration. It must be:
- **Self-contained**: All necessary context included
- **State-aware**: References progress files Claude should read
- **Action-oriented**: Clear next steps
- **Bounded**: Knows when to stop

Build the prompt using this structure:

---

```markdown
# Ralph Loop Task: <task-name>

## Your Mission

<problem statement from PRD or freeform prompt>

## Completion Criteria

When ALL of the following are true, output exactly: <promise>ALL STORIES PASS</promise>

<list each success criterion as a checkbox>

**CRITICAL**: Do NOT output the completion promise unless ALL criteria are actually met. The loop will continue until you output this exact text or max iterations is reached.

---

## CRITICAL INSTRUCTIONS

You are in a Ralph loop. Each iteration, you receive this same prompt. Your memory persists ONLY through files on disk. Follow these instructions exactly.

### 1. Read State First (EVERY ITERATION)

Before doing ANY work, read these files to understand current state:

- `.claude/ralph/<task-name>/progress.md` - What you've learned, where you are, what iteration you're on
- `.claude/ralph/<task-name>/AGENTS.md` - Persistent patterns and architectural decisions
- `.claude/ralph/<task-name>/prd.json` - Current story status (which stories pass)

**DO NOT** start working until you've read these files. They contain your memory from previous iterations.

### 2. Progress Tracking (MANDATORY)

After EACH meaningful action, update `.claude/ralph/<task-name>/progress.md`:

**Learnings section** (append-only):
```
[Iteration N] <what you learned>
```
Example:
```
[Iteration 3] Database requires await on pool.connect() before queries
[Iteration 4] Test file must be named *.test.ts to be discovered
```

**Current State section**:
- Update "Working on" with current focus
- Update "Current Story" with active story ID
- Update "Last verification" with most recent test/check result
- Increment "Attempts on current issue" if retrying same problem

**Story Status section**:
- Check off stories as they pass: `- [x] US-001: Create endpoint`

**Iteration History section**:
- Add brief entry for this iteration

### 3. Context Health

**Commit frequently**:
- After each passing test
- After each working feature
- Use descriptive commit messages
- This creates recovery points

**Summarize on milestones**:
- When completing a story, add insights to AGENTS.md
- Document patterns discovered, architectural decisions
- Keep AGENTS.md as distilled knowledge

**Archive if progress.md grows large**:
- If > 300 lines, move old iterations to progress_archive.md
- Keep active iteration history manageable

### 4. TDD Workflow

For each story or feature:

1. **Write test FIRST**
   - Define what success looks like in code
   - Test should be specific and focused

2. **Run test - confirm it FAILS**
   - This proves the test is valid
   - If it passes, test may be wrong

3. **Implement minimal code**
   - Just enough to make test pass
   - Don't over-engineer

4. **Run test - confirm it PASSES**
   - If fails, debug and fix
   - Update progress.md with learnings

5. **Refactor if needed**
   - Clean up while tests still pass
   - Run tests after refactoring

6. **Commit and document**
   - Commit working code
   - Update progress.md
   - Update AGENTS.md if pattern discovered

### 5. Verification Steps

<verification method from PRD>

Run verification after implementing each story:
- **Command**: `<verification command if applicable>`
- **Expected result**: <what success looks like>
- **If verification fails**: Note in progress.md, attempt fix, re-verify

### 6. Escape Hatches

**If stuck after 3 attempts on the same issue**:

1. **Document the issue** in progress.md:
   ```
   ### Blocked: <issue description>
   - Attempted: <what you tried>
   - Error: <exact error message>
   - Hypothesis: <why it might be failing>
   ```

2. **Try ONE alternative approach**:
   - Different library or method
   - Simplified implementation
   - Ask if requirement can be relaxed

3. **If still stuck after alternative**:
   - Mark story as BLOCKED in prd.json: `"blocked": true, "blocked_reason": "..."`
   - Add to "Blocked Stories" section in progress.md
   - Move to NEXT story (don't spin forever)

4. **If ALL stories are blocked**:
   - Create comprehensive summary in progress.md
   - List all blockers and what was attempted
   - Do NOT output false completion promise
   - The loop will continue until max iterations

**Never output the completion promise to escape a difficult situation. That defeats the purpose of the loop.**

### 7. Project CLAUDE.md Updates

After completing a story/phase, check if any learnings should be promoted to the project-level CLAUDE.md:

**Promote to CLAUDE.md when:**
- Discovered a project-wide convention (naming, structure, patterns)
- Found a command or workflow that applies beyond this task
- Identified a gotcha that future tasks should know about
- Established an architectural decision affecting the whole project

**Do NOT promote:**
- Task-specific implementation details
- Temporary workarounds
- Learnings only relevant to this feature

**Update format:**
Append to CLAUDE.md under a "## Discovered Patterns" or relevant existing section:
```
## Discovered Patterns

### <Category>
- <pattern description> (discovered during <task-name>)
```

**Location:**
- Read: `./CLAUDE.md` (project root)
- Write: Append new patterns, never remove existing content

**Relationship to AGENTS.md:**
- AGENTS.md = Task-specific patterns (stays in `.claude/ralph/<task>/`)
- CLAUDE.md = Project-wide conventions (promoted from AGENTS.md)

---

## User Stories

<For PRD mode, list all stories from prd.json>

### Current Focus: <first non-passing, non-blocked story>

**Story ID**: <id>
**Title**: <title>
**Description**: <description>

**Acceptance Criteria**:
<list criteria as checkboxes>

**Verification**: <story-specific verification>

### Remaining Stories

<list other stories with status indicators>
- [ ] US-002: <title>
- [ ] US-003: <title>
- [x] US-001: <title> (PASS)
- [BLOCKED] US-004: <title>

---

## What To Do Now

1. **Read state files** - progress.md, AGENTS.md, prd.json, and ./CLAUDE.md
2. **Identify current iteration** from progress.md
3. **Determine current story** - first non-passing, non-blocked story
4. **Check attempt count** - if 3+ attempts on same issue, use escape hatch
5. **Follow TDD workflow** for current story
6. **Update progress.md** after each action
7. **Run verification** when story seems complete
8. **Update prd.json** when story passes: `"passes": true`
9. **Update AGENTS.md** with task-specific patterns discovered
10. **Promote to CLAUDE.md** any project-wide conventions discovered
11. **Commit working code** with descriptive message
12. **Move to next story** until all pass
13. **When ALL criteria met**, output: <promise>ALL STORIES PASS</promise>

---

## Remember

- You are in a LOOP - your work from previous iterations is in the files
- READ STATE FIRST every iteration (progress.md, AGENTS.md, prd.json, CLAUDE.md)
- NEVER output the completion promise unless it's TRUE
- Commit often, document always
- If stuck 3 times, use escape hatch - don't spin forever
- Progress through stories methodically
- Your learnings in progress.md help future iterations avoid mistakes
- Promote project-wide patterns to CLAUDE.md, keep task-specific in AGENTS.md
```

---

### Phase 4: Return the Built Prompt

Output the complete master prompt ready for the /ralph command:

```
Master prompt built for Ralph loop.

**Summary**:
- Task: <task-name>
- Mode: <prd|freeform>
- Stories: <count> (<passing> passing, <blocked> blocked)
- Current focus: <first incomplete story>
- Completion promise: "ALL STORIES PASS"

**Working files**:
- .claude/ralph/<task-name>/progress.md
- .claude/ralph/<task-name>/AGENTS.md
- .claude/ralph/<task-name>/prd.json
- ./CLAUDE.md (project root - for project-wide patterns)

The master prompt includes:
- Mission and completion criteria
- State file reading instructions
- Progress tracking requirements
- TDD workflow guidance
- Verification steps
- Escape hatch patterns
- Story list with status

Ready to invoke ralph-loop with this prompt.
```

---

## Key Principles

### 1. The Prompt is the Contract

Everything Claude needs to succeed must be in the prompt. The prompt is fed fresh each iteration - Claude doesn't remember previous iterations except through:
- Files on disk (progress.md, AGENTS.md, prd.json, code files)
- Git history
- Test results

### 2. Progress Files are Memory

Since Ralph loops re-feed the same prompt, persistent files are how Claude "remembers":
- **progress.md**: Append-only learnings, current state, iteration history
- **AGENTS.md**: Task-specific patterns and architectural decisions
- **CLAUDE.md**: Project-wide conventions (promoted from AGENTS.md)
- **prd.json**: Story completion status

### 3. Small Stories Beat Big Stories

Stories should be completable in 1-3 iterations. If a story takes more than 5 iterations:
- It's too big - should have been broken down
- There's a blocker - use escape hatch

### 4. Verification is Essential

Every story must have a verification method. Without it, Claude can't objectively know when it's done. Prefer automated verification (tests, type checks) over manual.

### 5. Escape Hatches Prevent Infinite Loops

When stuck, Claude should:
1. Document the issue thoroughly
2. Try an alternative approach
3. Mark as blocked and move on
4. NEVER lie about completion

---

## Plan Mode Adaptations

When `.claude/ralph/<task-name>/plan.json` exists (created via `/ralph-freeform`):

**Key differences from PRD mode**:
- **Phases instead of stories**: Larger chunks of work with steps
- **Simpler structure**: 2-5 phases vs 5+ user stories
- **Goal-focused**: Single goal with phases to achieve it
- **Completion promise**: `<promise>ALL PHASES COMPLETE</promise>`

**Master prompt adaptations for Plan Mode**:
- Replace "User Stories" section with "Phases" section
- Replace story IDs (US-001) with phase IDs (P1, P2)
- Replace `prd.json` references with `plan.json`
- Update status tracking for phases instead of stories

**Phase Status in plan.json**:
```json
{
  "id": "P1",
  "name": "Phase name",
  "steps": ["step 1", "step 2"],
  "verification": "How to verify",
  "complete": true,  // Update when phase done
  "notes": "Any notes from implementation"
}
```

**What To Do Now (Plan Mode)**:
1. Read state files - progress.md, AGENTS.md, plan.json, and ./CLAUDE.md
2. Identify current iteration from progress.md
3. Determine current phase - first non-complete phase
4. Check attempt count - if 3+ attempts on same issue, use escape hatch
5. Work through current phase steps
6. Update progress.md after each action
7. Run verification when phase seems complete
8. Update plan.json when phase passes: `"complete": true`
9. Update AGENTS.md with task-specific patterns discovered
10. Promote to CLAUDE.md any project-wide conventions discovered
11. Commit working code with descriptive message
12. Move to next phase until all complete
13. When ALL phases complete, output: `<promise>ALL PHASES COMPLETE</promise>`

---

## Raw Freeform Mode Adaptations

When neither PRD nor plan exists (raw prompt passed to /ralph):

- **Single implicit phase**: The entire task is one phase
- **Inferred criteria**: Extract testable criteria from description
- **Completion promise**: Use `<promise>TASK COMPLETE</promise>`
- **Simpler structure**: No phase list, just task description and criteria
- **Minimal tracking**: progress.md still used, but no JSON status file

---

## References

Load these for detailed guidance:

- **references/prompt-patterns.md** - Best practices for prompt writing
- **references/story-sizing.md** - How to size user stories for Ralph
- **references/escape-hatches.md** - Detailed recovery patterns

---

## Integration with ralph-loop

This skill builds the prompt; the actual looping is handled by the official `ralph-loop` plugin:

```bash
/ralph-loop "<master-prompt>" --max-iterations <N> --completion-promise "ALL STORIES PASS"
```

The stop hook in ralph-loop:
- Intercepts Claude's exit attempts
- Re-feeds the same prompt
- Detects completion promise to exit loop
- Respects max-iterations limit

Our progress.md, AGENTS.md, and prd.json provide the persistent context that makes each iteration productive.
