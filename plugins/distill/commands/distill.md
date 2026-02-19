---
description: Distill conversation into structured context files
---

# Distillation Task

You are distilling a conversation session into structured context files.

## Instructions

1. **Review the ENTIRE conversation history** for:
   - New information (clients, projects, people, decisions)
   - Strategic thinking (options considered, tradeoffs, reasoning)
   - Updates to existing context (progress, status changes)
   - Goals with dates, deadlines, and progress
   - Important decisions and their rationale
   - Uncertainty and open questions

2. **Check for existing context** using Bash tool:
   ```bash
   ls context/ 2>/dev/null
   ```
   - If context/ doesn't exist, you'll create it
   - If it exists, list files to see what's there
   - Read `context/index.md` first if it exists

3. **Create directories if needed** using Bash tool:
   ```bash
   mkdir -p context context-archive
   ```

4. **Create or update context files**:
   - Use Write tool to create new files as needed
   - Use Edit tool to update existing files
   - Organize information naturally based on conversation content
   - Preserve narrative and relationships between concepts
   - Keep content concise but complete
   - User will confirm each change

5. **Maintain index.md**:
   - If no index.md exists, create it with Write tool
   - If creating new context files, update index.md to describe them
   - Index should briefly explain each file and when to load it
   - Format:
     ```markdown
     # Context Index

     ## Available Files

     ### filename.md
     Brief description of what's in this file
     *Load when: specific situations*

     ## Last Updated
     YYYY-MM-DD
     ```

6. **Create session archive** using Write tool:
   - Filename: `context-archive/YYYY-MM-DD-brief-topic.md`
   - Include: date, conversation summary, key insights extracted
   - Note: which context files were created/updated and why

7. **Inform user** to run `/clear` to reset the conversation with context preserved

## File Organization Guidelines

**Let the conversation guide structure.** Common patterns that often emerge:

### goals.md
If conversation includes goals, deadlines, or priorities:
- Use temporal tracking (start dates, deadlines, progress %)
- Use checkboxes for completion tracking
- Organize by timeframe or however makes sense
- Example format:
  ```markdown
  ## Immediate Goals
  - [ ] Goal title
    - Started: YYYY-MM-DD
    - Deadline: YYYY-MM-DD
    - Progress: Current status
  ```

### business.md
If conversation includes business context:
- Clients, customers, partnerships
- Team members and roles
- Revenue and metrics
- Operational details

### strategy.md
If conversation includes strategic thinking:
- Market positioning
- Strategic decisions and pivots
- Competitive landscape
- Value proposition

### decisions.md
If significant decisions were made:
- Document the decision and date
- Options considered
- Reasoning and tradeoffs
- Expected impact

**You decide what files make sense based on what was discussed.**

## Writing Guidelines

- **Use headers and subheaders** for hierarchy
- **Include specific details** - dates, numbers, names
- **Capture "why" not just "what"** - reasoning matters
- **Avoid duplication** - information should live in one primary place
- **Link between files** - reference other context files instead of duplicating
  - Example: "See strategy.md for pivot decision details"
  - Example: "Related goal in goals.md: Launch v2.0"
- **Use checkboxes** for trackable items
- **Preserve uncertainty** - "considering X vs Y" when undecided
- **Keep sections scannable** - use lists, short paragraphs

## Quality Checklist

Before completing distillation:
- [ ] Context directory exists
- [ ] index.md describes all files
- [ ] Significant information captured in appropriate files
- [ ] Goals have temporal tracking if applicable
- [ ] Strategic thinking and reasoning preserved
- [ ] Session archived
- [ ] User reminded to run `/clear`

## User Instructions

$ARGUMENTS
