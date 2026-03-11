---
description: Distill conversation into structured context files
---

# Distillation Task

You are distilling a conversation session into structured context files.

## Instructions

1. **Review the ENTIRE conversation history** for:
   - New information (clients, projects, people, decisions, or any domain-specific entities)
   - Strategic or analytical thinking (options considered, tradeoffs, reasoning)
   - Updates to existing context (progress, status changes)
   - Goals with dates, deadlines, and progress
   - Important decisions and their rationale
   - Uncertainty and open questions

2. **Discover the repo structure** using Bash tool:
   ```bash
   ls -1
   ```
   - Look for an index file (INDEX.md, README.md, etc.) and read it first — it will tell you how this repo is organized and what each directory is for
   - List top-level directories to understand the layout
   - Do NOT assume a fixed structure. This command is used across different repos (business context, personal health/finances, project notes, etc.)

3. **Map conversation content to existing structure**:
   - Find the directories and files that already exist
   - Update files that are clearly the right home for new information
   - If you need to create a new file, place it where it fits the existing pattern
   - If no relevant file exists yet, create one that matches the style and naming conventions of what's already there

4. **Create or update context files**:
   - Use Write tool to create new files as needed
   - Use Edit tool to update existing files
   - Organize information naturally based on conversation content
   - Preserve narrative and relationships between concepts
   - Keep content concise but complete
   - User will confirm each change

5. **Maintain the index file**:
   - Find the repo's index (INDEX.md, README.md, or similar)
   - If a new file was created, add it to the index
   - If the quick-reference or status section at the top of the index is stale, update it
   - If no index exists, create one that describes the structure

6. **Create session archive**:
   - Find where archives live in this repo (look for an `archive/` directory or similar)
   - If none exists, create `archive/`
   - Filename: `archive/YYYY-MM-DD-brief-topic.md`
   - Include: date, conversation summary, key insights extracted, which files were created/updated and why

7. **Inform user** to run `/clear` to reset the conversation with context preserved

## Writing Guidelines

- **Use headers and subheaders** for hierarchy
- **Include specific details** — dates, numbers, names
- **Capture "why" not just "what"** — reasoning matters
- **Avoid duplication** — information should live in one primary place
- **Link between files** — reference other files instead of duplicating
- **Use checkboxes** for trackable items
- **Preserve uncertainty** — "considering X vs Y" when undecided
- **Keep sections scannable** — use lists, short paragraphs
- **Match the style** of existing files in the repo

## Quality Checklist

Before completing distillation:
- [ ] Repo structure discovered and index read
- [ ] Significant information captured in appropriate existing files (or new files that fit the pattern)
- [ ] Index updated if new files were created or status has changed
- [ ] Goals have temporal tracking if applicable
- [ ] Strategic thinking and reasoning preserved
- [ ] Session archived
- [ ] User reminded to run `/clear`

## User Instructions

$ARGUMENTS
