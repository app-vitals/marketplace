---
name: terraform
description: This skill should be used when the user asks to "create Terraform config", "write a .tf file", "add a Terraform module", "review Terraform code", "generate tfvars", "set up infrastructure", "create cloud resources with Terraform", or when editing any .tf or .tfvars file. Provides opinionated best practices for Terraform development including version pinning, tagging, pre-commit validation, Terratest generation, state isolation, module composition, variable validation, and naming conventions.
---

# Terraform Best Practices

Opinionated Terraform skill distilled from 20+ years of real-world infrastructure experience. Applies automatically when working with Terraform configurations.

## When This Skill Activates

- Creating, editing, or reviewing `.tf` or `.tfvars` files
- Working with Terraform modules or providers
- Generating or suggesting Terraform configurations
- Running any Terraform CLI commands

## Practices Overview

Eight practices organized by enforcement mode:

| # | Practice | Mode | Summary |
|---|----------|------|---------|
| 1 | Exact version pinning | lint | Pin external modules to exact versions, no ranges |
| 2 | Conservative tags | lint | Minimal tags only — never add `owner` |
| 3 | Pre-commit workflow | auto | Run fmt, validate, init, plan before commits |
| 4 | Terratest generation | generate | Auto-generate unit + integration tests |
| 5 | State isolation | lint | Separate state files per environment |
| 6 | Module composition | lint | Small, focused modules — one responsibility each |
| 7 | Variable validation | lint | Validation blocks on all input variables |
| 8 | Naming conventions | lint | Flag inconsistent naming within the codebase |

For detailed rules with pass/fail examples, consult **`references/lint-rules.md`**.

---

## Lint Practices (1, 2, 5, 6, 7, 8)

Apply these checks when creating or reviewing Terraform code:

### 1. Exact Version Pinning (External Sources Only)

Pin every external module or provider to an exact version. No ranges (`~>`, `>=`), no missing versions. Local modules (`source = "./modules/foo"`) are exempt.

If no version is pinned on an external source, look up the latest version from the Terraform registry and suggest pinning to it. Version staleness is handled by Renovate Bot — do not flag outdated pins.

### 2. Conservative Tags and Labels

Keep tags minimal. Only include tags that serve a clear operational, compliance, or cost-allocation purpose. **Never add an `owner` tag under any circumstances.** When in doubt, leave the tag out.

### 5. State File Isolation

Dev, staging, and prod environments must use completely separate state files. Flag any backend configuration that could result in shared state across environments. Expect the pattern:

```
environments/
  dev/backend.tf
  staging/backend.tf
  prod/backend.tf
```

### 6. Module Composition

Prefer small, focused modules over large monolithic ones. Flag when a module:
- Manages more than 2-3 distinct resource types with no clear cohesion
- Exceeds ~200 lines without a clear single responsibility
- Has too many input variables with unrelated concerns

Encourage splitting into composable, single-purpose modules.

### 7. Variable Validation

All input variables should include explicit `validation` blocks so bad inputs fail fast at plan time. Flag variables that accept values where invalid inputs are possible but no validation block is present.

### 8. Naming Conventions

Flag obvious violations of consistent naming:
- Mixed styles within the same file (camelCase mixed with snake_case)
- Non-descriptive names (`var1`, `res`, `thing`)
- Inconsistent output naming across modules (`vpc_id` vs `vpcId`)

Consistency within the codebase is the goal — do not enforce a strict external schema.

---

## Auto Practice: Pre-Commit Workflow (3)

Before any Terraform code is committed, run these four commands automatically and silently in sequence:

```bash
terraform fmt
terraform validate
terraform init
terraform plan
```

**Behavior:**
- Run all four steps without prompting the user
- If any step produces errors or warnings, surface them clearly
- Do not block on the output — surface issues and let the user decide how to proceed

---

## Generate Practice: Terratest (4)

Whenever a Terraform module or resource is created or modified, automatically generate corresponding [Terratest](https://terratest.gruntwork.io/) tests alongside the Terraform code.

### File Placement

Tests live adjacent to the module they test:

```
modules/
  vpc/
    main.tf
    variables.tf
    outputs.tf
    test/
      vpc_unit_test.go
      vpc_integration_test.go
```

### What to Generate

- **Unit test** — validates Terraform plan output and structure without applying
- **Integration test** — applies the configuration and validates real resource behavior

For Terratest patterns, examples, and boilerplate, consult **`references/terratest-patterns.md`**.

---

## Additional Resources

### Reference Files

- **`references/lint-rules.md`** — Detailed pass/fail examples for all lint practices (version pinning, tags, state isolation, module composition, variable validation, naming)
- **`references/terratest-patterns.md`** — Terratest boilerplate, unit test patterns, integration test patterns, and file placement conventions
