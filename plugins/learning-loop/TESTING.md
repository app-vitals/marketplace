# Test Plan: learning-loop Plugin

## Setup

```bash
# Install the plugin from local path
claude plugin install ./plugins/learning-loop

# Restart Claude Code to load hooks
# Exit and run: claude
```

---

## Test 1: Session Start Hook

**Goal:** Verify session start shows staged count

**Steps:**
1. Make sure there are staged learnings in `.claude/CLAUDE.md`
2. Exit Claude Code
3. Start new session: `claude`
4. **Expected:** See "Learning Loop: X staged learning(s)" message

---

## Test 2: Hook Awareness (Ambient Detection)

**Goal:** Verify the UserPromptSubmit hook notices corrections

**Steps:**
1. Start fresh session in this repo
2. Ask Claude to do something wrong: "Create a Python requirements.txt using pip freeze"
3. Correct Claude: "Actually, use uv instead of pip for this project"
4. Complete the task
5. **Expected:** Claude offers "Want me to stage that as a learning?"
6. Say "yes"
7. **Expected:** Learning staged to `.claude/CLAUDE.md`

**Verify:**
```bash
cat .claude/CLAUDE.md
# Should see under "## Staged Learnings":
# - Use uv instead of pip...
```

---

## Test 3: Manual Capture (/learn)

**Goal:** Verify manual learning capture works

**Steps:**
1. Run: `/learn always run tests before committing`
2. **Expected:** Preview shown
3. Confirm
4. **Expected:** "Learning staged. Run /learn-promote to route..."

**Verify:**
```bash
grep "always run tests" .claude/CLAUDE.md
```

---

## Test 4: Review Staged (/learn-review)

**Goal:** Verify review shows all staged learnings

**Steps:**
1. Run: `/learn-review`
2. **Expected:** Shows count of staged learnings
3. **Expected:** Lists all staged learnings

---

## Test 5: Promote to CLAUDE.md (/learn-promote)

**Goal:** Verify simple learning promotes to project CLAUDE.md

**Steps:**
1. Run: `/learn-promote`
2. Select a simple correction (e.g., "use uv instead of pip")
3. **Expected:** Analysis suggests promoting to CLAUDE.md
4. Confirm
5. **Expected:** Moved from "## Staged Learnings" to "# Project Learnings"

**Verify:**
```bash
grep -B5 "uv instead of pip" .claude/CLAUDE.md
# Should be under "# Project Learnings", not "## Staged Learnings"
```

---

## Test 6: Promote to Existing Skill

**Goal:** Verify promotion finds and updates related skills

**Steps:**
1. Stage a learning related to ralph:
   `/learn ralph loop: prefer smaller story scopes, 1-2 iterations max`
2. Run: `/learn-promote`
3. **Expected:** Search finds `plugins/ralph-orchestrator/skills/ralph-orchestrator/`
4. **Expected:** Offers to update existing skill

---

## Test 7: Promote to New Skill

**Goal:** Verify complex learning can become a new skill

**Steps:**
1. Stage a complex learning:
   `/learn When debugging N+1 queries: 1) Check eager loading with includes(), 2) Look at query logs for repeated patterns, 3) Add preload for associations, 4) Verify with bullet gem`
2. Run: `/learn-promote`
3. Select the N+1 learning
4. **Expected:** Analysis recommends creating a new skill (procedural, multi-step)
5. Choose to create skill
6. **Expected:** Creates `.claude/skills/debug-n1-queries/SKILL.md` or similar

**Verify:**
```bash
ls .claude/skills/
cat .claude/skills/*/SKILL.md
```

---

## Test 8: Learning Analyzer Agent

**Goal:** Verify deep analysis works

**Steps:**
1. Have a conversation with some corrections/discoveries
2. Ask: "What did we learn in this session?"
3. **Expected:** Agent analyzes conversation, proposes learnings
4. Approve some
5. **Expected:** Staged to `.claude/CLAUDE.md`

---

## Cleanup

```bash
# Reset test artifacts (careful - removes all project learnings)
rm -rf .claude/CLAUDE.md .claude/skills/
```
