---
name: ralph-freeform
description: Create a structured freeform plan for Ralph loop execution. Interactive workflow that gathers context, asks clarifying questions, generates phases with verification steps, and outputs both human-readable PLAN.md and machine-readable plan.json. Use this for simpler tasks that don't need full user stories.
---

# Create Freeform Plan

Create a structured plan for freeform Ralph loop execution. Simpler than PRD - uses phases instead of user stories.

**Task name**: $1 (optional - will ask if not provided)

## When to Use This vs /prd

| Use `/ralph-freeform` | Use `/prd` |
|----------------------|------------|
| Single goal/feature | Multiple features |
| 2-5 phases of work | 5+ user stories |
| Simpler verification | Complex acceptance criteria |
| "Add a health endpoint" | "Build authentication system" |
| "Fix the login bug" | "Implement user management" |

## Workflow

### Step 1: Gather Context Automatically

Before asking questions, gather context from the codebase:

```bash
# Check for project type indicators
ls package.json pyproject.toml Cargo.toml go.mod Gemfile 2>/dev/null
```

Identify:
- **Language/framework**: From config files (package.json → Node.js, etc.)
- **Test framework**: From test directories or config
- **Existing patterns**: From directory structure

Use this context to:
- Suggest appropriate verification commands
- Generate relevant phases
- Avoid asking obvious questions

### Step 2: Ask Clarifying Questions

Ask these questions ONE AT A TIME (don't overwhelm):

1. **Task Name** (if not provided via $1):
   ```
   What should I call this task?
   Use a short, descriptive name like: "health-endpoint", "fix-login-bug", "add-validation"
   ```

2. **Goal**:
   ```
   What are you trying to accomplish? (1-2 sentences)
   Be specific - this becomes the mission statement for the Ralph loop.

   Examples:
   - "Add a /health endpoint that returns server status"
   - "Fix the bug where login fails on mobile Safari"
   - "Add input validation to the user registration form"
   ```

3. **Success Criteria**:
   ```
   How will we know when this is DONE?
   List 2-4 specific, testable criteria.

   Good examples:
   - "GET /health returns {status: 'ok'} with 200"
   - "Login works in Safari mobile (tested manually)"
   - "Invalid emails show error message, form doesn't submit"
   - "All existing tests still pass"

   Bad examples:
   - "It works" (too vague)
   - "Good UX" (not testable)
   ```

4. **Verification Method**:
   Based on gathered context, suggest options:
   ```
   How should completion be verified?

   Based on your project, I suggest:
   A) Run tests: `npm test` (detected Jest config)
   B) Type check: `npx tsc --noEmit`
   C) Manual verification: [describe what to check]
   D) Combination of above
   E) Other: [describe]
   ```

5. **Out of Scope** (optional):
   ```
   Anything that should NOT be attempted? (press Enter to skip)

   Examples:
   - "Don't change the database schema"
   - "Don't refactor other endpoints"
   - "Skip browser testing for now"
   ```

### Step 3: Generate Phases

Based on the goal, automatically generate 2-5 phases that:

**Phase Generation Rules**:
- Each phase should be completable in 1-2 Ralph iterations
- Phases build on each other logically
- Each phase has clear verification
- First phase is often "setup/understand current state"
- Last phase is often "verify everything works together"

**Example for "Add health endpoint"**:
```
Phase 1: Understand Current Setup
- Review existing route structure
- Identify where health endpoint should go
- Check for existing health check patterns
Verify: Can describe the route structure

Phase 2: Implement Health Endpoint
- Create health route handler
- Return {status: "ok", timestamp: Date.now()}
- Add route to main router
Verify: curl localhost:3000/health returns 200

Phase 3: Add Tests
- Write integration test for health endpoint
- Test success case
- Test response format
Verify: npm test passes

Phase 4: Final Verification
- Run full test suite
- Test endpoint manually
- Verify no regressions
Verify: All tests pass, endpoint works
```

### Step 4: Review with User

Present the generated plan:

```
Here's the plan I've generated:

## Goal
<goal statement>

## Success Criteria
- [ ] <criterion 1>
- [ ] <criterion 2>

## Phases

### P1: <phase name>
Steps:
- <step 1>
- <step 2>
Verify: <verification>

### P2: <phase name>
...

## Verification
Method: <method>
Command: <command if applicable>

## Out of Scope
- <item> (or "None specified")

---

Would you like to:
1. Approve this plan as-is
2. Add/remove phases
3. Adjust steps within a phase
4. Change verification method
5. Start over with different goal
```

Iterate until user approves.

### Step 5: Create Plan Files

Create the working directory:
```bash
mkdir -p .claude/ralph/<task-name>/
```

Write two files:

**PLAN.md** (human-readable):
```markdown
# Plan: <task-name>

**Created**: <timestamp>
**Status**: draft
**Type**: freeform

## Goal

<goal statement>

## Success Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] <criterion 3>

## Verification

**Method**: <method>
**Command**: `<command>` (if applicable)
**Description**: <what success looks like>

## Out of Scope

- <item 1>
- <item 2>

## Phases

### P1: <phase name>

**Steps**:
- [ ] <step 1>
- [ ] <step 2>

**Verify**: <how to verify phase complete>

**Status**: pending

---

### P2: <phase name>

...

## Completion Checklist

Before outputting the completion promise, verify:
- [ ] All phases completed
- [ ] All success criteria met
- [ ] Verification passes
- [ ] No known regressions
```

**plan.json** (machine-readable):
```json
{
  "name": "<task-name>",
  "created_at": "<ISO timestamp>",
  "status": "draft",
  "type": "plan",
  "goal": "<goal statement>",
  "success_criteria": [
    "<criterion 1>",
    "<criterion 2>"
  ],
  "verification": {
    "method": "<test|typecheck|manual|api|other>",
    "command": "<command if applicable>",
    "description": "<what success looks like>"
  },
  "out_of_scope": [
    "<item 1>"
  ],
  "phases": [
    {
      "id": "P1",
      "name": "<phase name>",
      "steps": [
        "<step 1>",
        "<step 2>"
      ],
      "verification": "<how to verify>",
      "complete": false,
      "notes": ""
    },
    {
      "id": "P2",
      "name": "<phase name>",
      "steps": ["..."],
      "verification": "...",
      "complete": false,
      "notes": ""
    }
  ]
}
```

### Step 6: Confirm and Provide Next Steps

```
Plan created successfully!

Location: .claude/ralph/<task-name>/
Files:
  - PLAN.md (human-readable - review and edit as needed)
  - plan.json (machine-readable for Ralph loop)

Summary:
  - Task: <task-name>
  - Goal: <goal summary>
  - Phases: <count>
  - Verification: <method>

To start the Ralph loop:
  /ralph <task-name>

To set iteration limit:
  /ralph <task-name> --max-iterations 20

To edit the plan before starting:
  Open .claude/ralph/<task-name>/PLAN.md in your editor
```

## Tips for Good Freeform Plans

**Right-sized phases**:
- 1-2 Ralph iterations per phase
- Clear, focused objective
- Concrete verification

**Clear goal statement**:
- One sentence
- Specific outcome
- No vague words like "improve" or "better"

**Testable success criteria**:
- Each criterion has yes/no answer
- Prefer automated verification
- 2-4 criteria is ideal

**When to use /prd instead**:
- Task has 5+ distinct features
- Need detailed acceptance criteria per feature
- Multiple stakeholder concerns
- Long-running project work
