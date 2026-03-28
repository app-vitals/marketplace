# Terraform

Opinionated Terraform best practices for Claude Code. Activates automatically when working with `.tf` or `.tfvars` files — no commands to remember, no manual invocation.

Distilled from 20+ years of real-world infrastructure experience.

## Installation

```
/plugin install terraform@app-vitals/marketplace
```

That's it. The skill activates whenever Claude Code touches Terraform configurations.

## What It Does

Eight practices, three enforcement modes:

| # | Practice | Mode | What happens |
|---|----------|------|--------------|
| 1 | Exact version pinning | lint | Flags external modules without exact version pins |
| 2 | Conservative tags | lint | Blocks `owner` tags, flags unnecessary metadata tags |
| 3 | Pre-commit workflow | auto | Runs `fmt` → `validate` → `init` → `plan` before commits |
| 4 | Terratest generation | generate | Creates unit + integration tests alongside modules |
| 5 | State isolation | lint | Flags shared state across environments |
| 6 | Module composition | lint | Flags monolithic modules, encourages single-responsibility |
| 7 | Variable validation | lint | Flags input variables missing validation blocks |
| 8 | Naming conventions | lint | Flags inconsistent naming within the codebase |

### Enforcement Modes

- **lint** — checks applied when creating or reviewing Terraform code. Issues are surfaced; the user decides how to proceed.
- **auto** — runs automatically without prompting. Errors and warnings are surfaced.
- **generate** — produces new files (Terratest tests) alongside Terraform code.

## Examples

### Version Pinning

The skill catches missing or ranged version constraints on external modules and suggests the exact latest version:

```hcl
# Flagged — range constraint
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}

# Fixed
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
}
```

Local modules (`source = "./modules/foo"`) are exempt. Version staleness is handled by Renovate Bot.

### Conservative Tagging

Only tags with a clear operational purpose are allowed. `owner` is never added:

```hcl
# Flagged
tags = {
  Name    = "web-server"
  Owner   = "dave@example.com"
  Team    = "platform"
}

# Fixed
tags = {
  Name        = "web-server"
  Environment = "prod"
}
```

### Automatic Terratest

When a module is created or modified, the skill generates adjacent tests:

```
modules/vpc/
  main.tf
  variables.tf
  outputs.tf
  test/
    vpc_unit_test.go          # validates plan output
    vpc_integration_test.go   # applies and validates real resources
```

## Plugin Structure

```
terraform/
├── .claude-plugin/
│   └── plugin.json
├── README.md
└── skills/terraform/
    ├── SKILL.md                         # Core skill — practice summaries and workflow
    └── references/
        ├── lint-rules.md                # Detailed pass/fail examples for lint practices
        └── terratest-patterns.md        # Test boilerplate, provider patterns, CI integration
```

## Design Decisions

- **No commands.** The skill triggers on context, not invocation. If you're touching `.tf` files, it's active.
- **Lint, don't block.** Practices are advisory. The skill surfaces issues and lets the user decide — no gatekeeping.
- **Progressive disclosure.** SKILL.md stays lean. Detailed examples and Terratest patterns live in `references/` and load only when needed.
- **External sources only for version pinning.** Local modules are exempt — they version with the repo.
- **Renovate handles staleness.** The skill enforces that a pin exists, not that it's the latest. Renovate Bot handles upgrades.
