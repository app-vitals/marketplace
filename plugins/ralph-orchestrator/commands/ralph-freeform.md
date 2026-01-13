---
name: ralph-freeform
description: Create a structured freeform plan for Ralph loop execution. Interactive workflow that gathers context, asks clarifying questions, generates phases with verification steps, and outputs both human-readable PLAN.md and machine-readable plan.json. Supports code implementation, analysis/documentation, and investigation tasks.
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
| "Create cost estimate" | "Multi-phase project planning" |

## Workflow

### Step 1: Gather Context and Discover Integrations

Before asking questions, gather context from the codebase:

```bash
# Check for project type indicators
ls package.json pyproject.toml Cargo.toml go.mod Gemfile 2>/dev/null

# Discover MCP servers
find . -name ".mcp.json" -type f 2>/dev/null | head -5
```

**Identify project context**:
- **Language/framework**: From config files (package.json → Node.js, etc.)
- **Test framework**: From test directories or config
- **Existing patterns**: From directory structure

**Discover available integrations**:
- **MCP Servers**: Parse any `.mcp.json` files found (Sentry, Trello, Toggl, etc.)
- **MCP Tools**: Use `ListMcpResourcesTool()` to see available tools

Use this context to:
- Suggest appropriate verification commands
- Generate relevant phases
- Recommend integrations based on task type
- Avoid asking obvious questions

### Step 2: Determine Task Type

Ask this question FIRST before other clarifying questions:

```
What type of task is this?

A) Code Implementation (default) - Write or modify code, fix bugs, add features
B) Analysis/Documentation - Research, estimate, document, or produce a written deliverable
C) Investigation/Debugging - Find root cause of an issue, explore unknowns

Choose the option that best matches your goal.
```

Store the task type for use in subsequent questions and phase generation.

---

## Task Type: Code Implementation (Default)

Use this flow when the user selects **Code Implementation** or doesn't specify.

### Step 3A: Ask Clarifying Questions (Code Implementation)

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

### Step 4A: Generate Phases (Code Implementation)

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

---

## Task Type: Analysis/Documentation

Use this flow when the user selects **Analysis/Documentation**.

### Step 3B: Ask Clarifying Questions (Analysis/Documentation)

Ask these questions ONE AT A TIME:

1. **Task Name** (if not provided via $1):
   ```
   What should I call this task?
   Use a short, descriptive name like: "feature-estimate", "architecture-doc", "cost-analysis"
   ```

2. **Deliverable**:
   ```
   What document or deliverable are you producing? (1-2 sentences)
   Be specific about the output format and audience.

   Examples:
   - "A cost estimate document for the client covering 3 new features"
   - "Architecture documentation for the authentication system"
   - "Technical analysis comparing two implementation approaches"
   - "Sprint planning breakdown with story points"
   ```

3. **Required Sections/Content**:
   ```
   What sections or information MUST be included in the deliverable?
   List 3-6 specific items that define completeness.

   Examples:
   - "Executive summary"
   - "Per-feature cost breakdown"
   - "Timeline with milestones"
   - "Technical complexity analysis"
   - "Assumptions and risks"
   - "Recommendations"
   ```

4. **Input Sources**:
   ```
   What materials need to be analyzed to produce this deliverable?

   Examples:
   - "Three PDF specifications in the project root"
   - "The existing codebase (hifriends-api, hifriends-app)"
   - "Current architecture diagrams"
   - "Competitor analysis documents"

   List all relevant files, directories, or external sources.
   ```

5. **Verification Method**:
   ```
   How will completion be validated?

   A) Checklist review - Document contains all required sections
   B) Client/stakeholder review - Ready for presentation
   C) Peer review - Another team member validates
   D) Self-review against criteria
   E) Other: [describe]
   ```

6. **Out of Scope** (optional):
   ```
   Anything that should NOT be included? (press Enter to skip)

   Examples:
   - "Don't include implementation details"
   - "Skip competitor pricing"
   - "Exclude timeline beyond Q1"
   ```

### Step 4B: Generate Phases (Analysis/Documentation)

**Phase Generation Rules for Documentation**:
- First phase: Gather and review all input materials
- Middle phases: Analyze each major area or feature
- Later phase: Draft document structure and content
- Final phase: Review, refine, and finalize deliverable

**Example for "Feature cost estimate"**:
```
Phase 1: Gather and Review Input Materials
- Read all specification PDFs
- Review existing codebase structure
- Identify integration points
Verify: Have notes on each input source

Phase 2: Analyze Feature 1 (Background Uploads)
- Review iOS background upload requirements
- Assess current upload queue implementation
- Identify complexity factors
Verify: Have complexity assessment and rough estimate

Phase 3: Analyze Feature 2 (Unmatched Photo Invite)
- Review invite flow mockups and requirements
- Assess API and app changes needed
- Identify AWS Rekognition integration points
Verify: Have complexity assessment and rough estimate

Phase 4: Analyze Feature 3 (Friend Suite)
- Review friend tab, search, and profile requirements
- Assess database schema changes
- Identify push notification requirements
Verify: Have complexity assessment and rough estimate

Phase 5: Draft Cost Estimate Document
- Create document structure
- Write executive summary
- Compile per-feature estimates
- Add timeline and assumptions
Verify: Document has all required sections

Phase 6: Review and Finalize
- Review against success criteria
- Ensure estimates are justified
- Polish formatting and clarity
Verify: Document ready for client presentation
```

---

## Task Type: Investigation/Debugging

Use this flow when the user selects **Investigation/Debugging**.

### Step 3C: Ask Clarifying Questions (Investigation/Debugging)

Ask these questions ONE AT A TIME:

1. **Task Name** (if not provided via $1):
   ```
   What should I call this investigation?
   Use a short, descriptive name like: "login-failure-investigation", "performance-analysis", "memory-leak-debug"
   ```

2. **Problem Statement**:
   ```
   What problem or question are you investigating? (1-3 sentences)
   Be specific about symptoms, errors, or unknowns.

   Examples:
   - "Users report login fails intermittently on iOS"
   - "API response times have degraded over the past week"
   - "Memory usage grows unbounded after 2 hours"
   - "Need to understand how the face matching pipeline works"
   ```

3. **Success Definition**:
   ```
   What would count as "investigation complete"?
   List 2-4 specific outcomes.

   Examples:
   - "Root cause identified and documented"
   - "Can reproduce the issue consistently"
   - "Have a fix implemented and tested"
   - "Understand the system well enough to explain it"
   ```

4. **Known Information**:
   ```
   What do you already know about this problem?

   Include:
   - Error messages or logs
   - When it started
   - What's been tried
   - Related recent changes

   Or say "Starting from scratch" if unknown.
   ```

5. **Verification Method**:
   ```
   How will you confirm the investigation is complete?

   A) Root cause documented with evidence
   B) Issue reproduced and fix verified
   C) System behavior understood and documented
   D) Stakeholder accepts findings
   E) Other: [describe]
   ```

### Step 4C: Generate Phases (Investigation/Debugging)

**Phase Generation Rules for Investigation**:
- First phase: Reproduce or observe the issue
- Middle phases: Form and test hypotheses
- Later phase: Identify root cause
- Final phase: Document findings and/or implement fix

**Example for "Login failure investigation"**:
```
Phase 1: Reproduce the Issue
- Set up test environment
- Attempt to reproduce on iOS
- Capture logs and network traces
Verify: Can reproduce issue OR have evidence it's intermittent

Phase 2: Gather Evidence
- Review error logs in Sentry
- Check recent code changes
- Review authentication flow
Verify: Have list of potential causes

Phase 3: Test Hypotheses
- Test hypothesis 1: Token expiration
- Test hypothesis 2: Network timeout
- Test hypothesis 3: Race condition
Verify: Have narrowed down to likely cause

Phase 4: Confirm Root Cause
- Verify hypothesis with targeted testing
- Document the exact failure mode
- Identify when/why this started
Verify: Root cause confirmed with evidence

Phase 5: Document and/or Fix
- Document findings in investigation report
- If fix is in scope: implement and test
- Update CLAUDE.md with learnings
Verify: Findings documented, fix verified if applicable
```

---

## Step 5: Suggest Relevant Integrations (All Task Types)

Based on discovered integrations from Step 1, suggest relevant ones:

**For Implementation tasks**:
- Code review plugins → "Add a review phase at the end?"
- Sentry → "Use Sentry to monitor for errors after deployment?"

**For Documentation tasks**:
- No special integrations typically needed

**For Investigation tasks**:
- Sentry → "Use Sentry to fetch error details and stack traces?"
- Debugging plugins → "Include debugging toolkit for analysis?"

Present discovered integrations:
```
I found these integrations that could help:

MCP Servers:
- Sentry (mcp.sentry.dev) - Error tracking and issue details

Would you like to include any of these in the plan?
1. Yes, include Sentry for [error investigation / monitoring / etc.]
2. No, skip integrations
3. Let me specify which ones
```

Record selected integrations for inclusion in the plan files.

---

## Step 6: Review with User (All Task Types)

Present the generated plan:

```
Here's the plan I've generated:

## Task Type
<Code Implementation | Analysis/Documentation | Investigation/Debugging>

## Goal / Deliverable / Problem
<goal statement or deliverable description or problem statement>

## Success Criteria
- [ ] <criterion 1>
- [ ] <criterion 2>

## Available Integrations
- <integration 1> - <how it will be used>
(or "None configured")

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
5. Modify integrations
6. Start over with different goal
```

Iterate until user approves.

## Step 7: Create Plan Files (All Task Types)

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
**Task Type**: <implementation|documentation|investigation>

## Goal / Deliverable / Problem

<goal statement, deliverable description, or problem statement>

## Success Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>
- [ ] <criterion 3>

## Input Sources (for documentation/investigation)

- <source 1>
- <source 2>

## Available Integrations

- **<Integration Name>** (<type: mcp|plugin>) - <how it will be used>

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
- [ ] Deliverable is complete (documentation) / Issue understood (investigation) / Code works (implementation)
```

**plan.json** (machine-readable):
```json
{
  "name": "<task-name>",
  "created_at": "<ISO timestamp>",
  "status": "draft",
  "type": "plan",
  "task_type": "<implementation|documentation|investigation>",
  "goal": "<goal statement, deliverable description, or problem statement>",
  "success_criteria": [
    "<criterion 1>",
    "<criterion 2>"
  ],
  "input_sources": [
    "<source 1 - for documentation/investigation tasks>"
  ],
  "integrations": [
    {
      "name": "<Integration Name>",
      "type": "<mcp|plugin>",
      "usage": "<how it will be used in this task>",
      "tools": ["<tool_name_1>", "<tool_name_2>"]
    }
  ],
  "verification": {
    "method": "<test|typecheck|manual|checklist|review|other>",
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

## Step 8: Confirm and Provide Next Steps

```
Plan created successfully!

Location: .claude/ralph/<task-name>/
Files:
  - PLAN.md (human-readable - review and edit as needed)
  - plan.json (machine-readable for Ralph loop)

Summary:
  - Task: <task-name>
  - Type: <implementation|documentation|investigation>
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

---

## Tips for Good Freeform Plans

### For Code Implementation
**Right-sized phases**:
- 1-2 Ralph iterations per phase
- Clear, focused objective
- Concrete verification (prefer automated tests)

**Clear goal statement**:
- One sentence
- Specific outcome
- No vague words like "improve" or "better"

### For Analysis/Documentation
**Right-sized phases**:
- Each analysis phase covers one logical area
- Draft and review are separate phases
- Verification is checklist-based

**Clear deliverable**:
- Specify output format (document, spreadsheet, etc.)
- Name the audience (client, team, stakeholders)
- List required sections explicitly

### For Investigation/Debugging
**Right-sized phases**:
- Reproduce before investigating
- One hypothesis per phase
- Document findings as you go

**Clear problem statement**:
- Include symptoms and error messages
- Note when it started
- List what's already been tried

---

## When to Use /prd Instead

- Task has 5+ distinct features
- Need detailed acceptance criteria per feature
- Multiple stakeholder concerns
- Long-running project work
