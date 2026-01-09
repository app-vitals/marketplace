# app-vitals Marketplace

A marketplace of Claude Code plugins.

## Installation

Add this marketplace to Claude Code:

```
/plugin marketplace add app-vitals/marketplace
```

## Available Plugins

### ralph-orchestrator

Structured orchestration for Ralph loops with PRD support, progress tracking, TDD guidance, and escape hatches. Wraps the official `ralph-loop` plugin to maximize autonomous development success.

```
/plugin install ralph-orchestrator@app-vitals/marketplace
```

**Commands:**
- `/prd <task-name>` - Create a PRD for complex multi-feature work
- `/ralph-freeform <task-name>` - Create a plan for simpler single-goal tasks
- `/ralph <task-name>` - Start an orchestrated Ralph loop

See [ralph-orchestrator documentation](plugins/ralph-orchestrator/README.md) for details.
