# Research

Lazy-loads project docs and runs web research in an isolated sub-agent. Given a task, it scans your project's `docs/` directory, selects only the relevant files, optionally web searches when local docs have gaps, and returns distilled context — never raw file dumps.

## Installation

```
/plugin install research@app-vitals/marketplace
```

## Commands

### /research

Load relevant docs and research for a given task.

**Usage:**
```
/research <task description>
```

**Examples:**
```
/research add retry logic to the payment service API calls
/research implement authentication for the API gateway
/research what's the data model for time entries
```

### /research-docs

Analyze the codebase and generate or update project documentation. Like `/init` but for your `docs/` directory.

**Usage:**
```
/research-docs                  # audit entire project
/research-docs billing          # focus on one module
```

**What it does:**
1. Scans your project structure to identify modules, services, and APIs
2. Audits existing `docs/` for gaps (missing docs) and staleness (outdated references)
3. Presents an audit summary and asks what to generate/update
4. Writes new docs and updates stale ones, matching your project's existing doc style
5. Updates `CLAUDE.md` references if applicable

## How It Works

1. Detects your project's docs directory (`docs/`, `documentation/`, or `doc/`)
2. Spawns an isolated research sub-agent (sonnet) that:
   - Scans available docs and selects only task-relevant files
   - Reads selected docs and extracts key information
   - Runs web search only when local docs have clear gaps
   - Distills everything into a structured summary
3. Returns clean context to your session — no intermediate reasoning, no raw dumps

The sub-agent is read-only and fully autonomous. It cannot modify files or ask questions. All reasoning stays inside the agent; only the curated result enters your conversation.

## Integration

Other plugins can invoke the research agent directly via the Agent tool. For example, [shipwright](../shipwright/README.md) uses it during planning and task discovery to automatically load relevant project docs.
