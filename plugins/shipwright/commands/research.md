---
description: Load relevant project docs and web research for a given task
argument-hint: <task description>
allowed-tools:
  - Read
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Agent
---

# Research: $ARGUMENTS

Load task-relevant documentation and research context using an isolated sub-agent. All reasoning happens in the sub-agent — only the distilled result enters this session.

## Step 1: Detect Docs Directory

Check for a documentation directory in the project root:

1. `Glob` for `docs/` — most common convention
2. If not found, check `documentation/`
3. If not found, check `doc/`

Also note whether `CLAUDE.md` exists at project root.

If no docs directory exists, inform the user and offer web-only research:

```
No docs/ directory found in this project.
Running web-only research for: $ARGUMENTS
```

## Step 2: Launch Research Agent

Spawn the `researcher` agent via the Agent tool. Pass a prompt that includes:

1. **The task:** `$ARGUMENTS`
2. **The docs directory path** (if found)
3. **Project name** (from `package.json` name field, or the current directory name)

Use `model: sonnet` and provide a clear, complete prompt — the agent has no prior context.

Example agent prompt:
```
Research the following task for this project:

Task: $ARGUMENTS
Project: {project name}
Docs directory: {docs path, or "none — web search only"}

Follow your standard workflow: discover docs, select relevant ones,
assess gaps, web search if needed, and return distilled results.
```

## Step 3: Present Results

The agent returns a structured "Research Results" block. Present it directly — do not summarize or reformat the agent's output.

If the agent found relevant docs, list them so the user knows what was loaded.
