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
| [dependabot-review](plugins/dependabot-review/README.md) | 0.1.0 | AI-powered triage of Dependabot PRs with patrol-style risk assessments |
| [discovery-report](plugins/discovery-report/README.md) | 1.1.0 | Generate dark-theme HTML discovery reports (with optional Playwright-based PDF export) |
| [shipwright](plugins/shipwright/README.md) | 1.8.0 | Structured dev pipeline — plan, build, review, research, ship |
| [terraform](plugins/terraform/README.md) | 1.0.0 | Opinionated Terraform best practices — version pinning, tagging, pre-commit validation, Terratest |
| [entropy-patrol](plugins/entropy-patrol/README.md) | 0.2.0 | Continuous code health enforcement via golden principles |
| [repo-readiness](plugins/repo-readiness/README.md) | 0.1.0 | Agent-readiness audit and bootstrapping for codebases |

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

### dependabot-review

```
/plugin install dependabot-review@app-vitals/marketplace
```

`/triage-dependabot-prs`

### discovery-report

```
/plugin install discovery-report@app-vitals/marketplace
```

No commands — skill activates automatically when asked to write a discovery report, post-mortem, or investigation summary.

### shipwright

```
/plugin install shipwright@app-vitals/marketplace
```

`/plan-session` · `/dev-task` · `/dev-loop` · `/metrics` · `/refresh-plan` · `/review` · `/research` · `/research-docs`

### terraform

```
/plugin install terraform@app-vitals/marketplace
```

No commands — skill activates automatically when working with `.tf` or `.tfvars` files.

### entropy-patrol

```
/plugin install entropy-patrol@app-vitals/marketplace
```

`/entropy-scan` · `/entropy-fix`

### repo-readiness

```
/plugin install repo-readiness@app-vitals/marketplace
```

`/repo-readiness`
