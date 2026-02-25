# app-vitals Marketplace

A marketplace of Claude Code plugins.

## Installation

Add this marketplace to Claude Code:

```
/plugin marketplace add app-vitals/marketplace
```

## Available Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| [ralph-orchestrator](plugins/ralph-orchestrator/README.md) | 1.6.0 | Structured orchestration for Ralph loops with PRD support |
| [damage-control](plugins/damage-control/README.md) | 1.0.0 | Defense-in-depth protection via PreToolUse hooks |
| [learning-loop](plugins/learning-loop/README.md) | 0.1.0 | Captures corrections and discoveries, promotes to skills |
| [pr-review](plugins/pr-review/README.md) | 0.2.0 | Interactive PR review with local drafts and batch processing |
| [meeting-transcripts](plugins/meeting-transcripts/README.md) | 1.0.0 | Browse and read meeting transcripts from the mt CLI |
| [distill](plugins/distill/README.md) | 0.1.0 | Distill conversations into persistent context files |

### ralph-orchestrator

```
/plugin install ralph-orchestrator@app-vitals/marketplace
```

`/prd` · `/ralph-freeform` · `/ralph`

### damage-control

```
/plugin install damage-control@app-vitals/marketplace
```

No commands — hooks activate automatically on install.

### learning-loop

```
/plugin install learning-loop@app-vitals/marketplace
```

`/learn` · `/learn-review` · `/learn-promote`

### pr-review

```
/plugin install pr-review@app-vitals/marketplace
```

`/review-pr` · `/ca-review-prs` · `/install-pr-review` · `/uninstall-pr-review`

### meeting-transcripts

```
/plugin install meeting-transcripts@app-vitals/marketplace
```

`/transcripts`

### distill

```
/plugin install distill@app-vitals/marketplace
```

`/distill`
