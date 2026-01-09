---
name: prd
description: Create a Product Requirements Document (PRD) for Ralph loop execution. Interactive workflow that guides through clarifying questions, generates right-sized user stories, and outputs both human-readable PRD.md and machine-readable prd.json.
---

# Create PRD

Create a structured Product Requirements Document for Ralph loop execution.

**Task name**: $1 (optional - will ask if not provided)

## Workflow

### Step 1: Gather Basic Information

Ask these questions ONE AT A TIME (don't overwhelm with all at once):

1. **Task Name** (if not provided via $1):
   ```
   What should I call this task?
   Use a short, descriptive name like: "todo-api", "auth-refactor", "payment-integration"
   ```

2. **Problem Statement**:
   ```
   What problem are you trying to solve? (1-2 sentences)
   Be specific - this becomes the mission statement for the Ralph loop.
   ```

3. **Success Criteria**:
   ```
   How will we know when this is DONE?
   List specific, testable criteria. These become your completion conditions.

   Good examples:
   - "All tests pass with >80% coverage"
   - "API responds in <200ms"
   - "User can complete checkout flow end-to-end"
   - "No TypeScript errors"

   Bad examples:
   - "It works" (too vague)
   - "Good performance" (not measurable)
   ```

4. **Scope Boundaries**:
   ```
   What is OUT OF SCOPE? What should NOT be attempted?
   This prevents scope creep during the loop.

   Examples:
   - "Authentication (handled separately)"
   - "Database migrations (manual process)"
   - "UI styling (will be done later)"
   ```

5. **Verification Method**:
   ```
   How should each story be verified?

   Options:
   A) Run tests (provide command, e.g., "npm test", "pytest")
   B) Type check (provide command, e.g., "npx tsc --noEmit")
   C) Manual browser verification (describe what to check)
   D) API testing (describe endpoints to test)
   E) Other (describe verification approach)
   ```

### Step 2: Generate User Stories

Based on the information gathered, generate 3-7 user stories that:

**Sizing Rules**:
- Each story should be completable in 1-3 Ralph iterations
- If a story seems bigger, break it down
- Good size: "Add a database column", "Create one API endpoint", "Add input validation"
- Too big: "Build the entire dashboard", "Implement full authentication"

**Dependency Order**:
- Stories execute sequentially, so dependencies must flow forward
- Database changes before API endpoints before UI
- Infrastructure before features

**Each story must have**:
- Clear acceptance criteria (testable, not vague)
- Verification method (how to prove it's done)
- No subjective language ("works correctly", "good UX")

Format each story as:
```json
{
  "id": "US-001",
  "title": "Short descriptive title",
  "description": "As a [user/developer], I want [feature] so that [benefit]",
  "acceptance_criteria": [
    "Specific testable criterion 1",
    "Specific testable criterion 2"
  ],
  "verification": "How to verify this story is done",
  "passes": false,
  "notes": ""
}
```

### Step 3: Review with User

Present the generated user stories and ask:

```
Here are the user stories I've generated:

1. US-001: [title]
   - [acceptance criteria summary]

2. US-002: [title]
   - [acceptance criteria summary]

[... etc ...]

Total: [N] stories

Would you like to:
1. Approve these stories as-is
2. Add more stories
3. Remove or combine stories
4. Adjust acceptance criteria
5. Reorder stories (change dependencies)
```

Iterate until the user approves the story list.

### Step 4: Create PRD Files

Create the working directory:
```bash
mkdir -p .claude/ralph/<task-name>/
```

Write two files:

**PRD.md** (human-readable):
Use the template from `./skills/ralph-orchestrator/assets/templates/prd_template.md` as a guide, filling in:
- Task name
- Timestamp
- Problem statement
- Success criteria
- Out of scope items
- Verification method
- All user stories with their details

**prd.json** (machine-readable):
```json
{
  "name": "<task-name>",
  "created_at": "<ISO timestamp>",
  "status": "draft",
  "problem_statement": "<from user>",
  "success_criteria": ["<criterion 1>", "<criterion 2>"],
  "out_of_scope": ["<item 1>", "<item 2>"],
  "verification": {
    "method": "<test|typecheck|browser|api|other>",
    "command": "<if applicable>",
    "description": "<description>"
  },
  "stories": [
    {
      "id": "US-001",
      "title": "...",
      "description": "...",
      "acceptance_criteria": ["...", "..."],
      "verification": "...",
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Step 5: Confirm and Provide Next Steps

```
PRD created successfully!

Location: .claude/ralph/<task-name>/
Files:
  - PRD.md (human-readable document - review and edit as needed)
  - prd.json (machine-readable for Ralph loop)

Summary:
  - Task: <task-name>
  - Stories: <count>
  - Verification: <method>

To start the Ralph loop:
  /ralph <task-name>

To start with a specific story:
  /ralph <task-name> --story US-001

To set iteration limit:
  /ralph <task-name> --max-iterations 30

To edit the PRD before starting:
  Open .claude/ralph/<task-name>/PRD.md in your editor
```

## Tips for Good PRDs

**Right-sized stories**:
- Can be completed in 1-3 Ralph iterations
- Have clear, testable acceptance criteria
- Build on previous stories logically

**Clear verification**:
- Every story must be verifiable
- Prefer automated verification (tests, type checks)
- Manual verification is okay but should be specific

**Realistic scope**:
- Start smaller than you think you need
- Can always add stories later
- Out of scope items prevent creep
