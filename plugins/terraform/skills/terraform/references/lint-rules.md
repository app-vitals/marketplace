# Terraform Lint Rules — Detailed Examples

Pass/fail examples for each lint practice. Consult this file when reviewing or writing Terraform code to apply the correct enforcement.

---

## 1. Exact Version Pinning (External Sources Only)

**Rule:** Any module or resource sourced from a public registry or remote URL must include an exact `version` attribute. No ranges, no constraints — exact only.

**Pass:**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
}
```

**Fail — version range:**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"   # ranges not allowed
}
```

**Fail — missing version:**
```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # missing version — look up latest and suggest pinning
}
```

**Exempt — local modules:**
```hcl
module "networking" {
  source = "./modules/networking"
  # no version needed for local modules
}
```

**Action:** If no version is pinned on an external source, look up the latest version from the Terraform registry and suggest pinning to that exact version.

**Note:** Version staleness is handled by Renovate Bot — do not flag outdated pins.

---

## 2. Conservative Tags and Labels

**Rule:** Keep tags minimal. Only include tags that serve a clear operational, compliance, or cost-allocation purpose.

**Always omit:**
- `owner` — never add this tag under any circumstances

**Default posture:** Conservative. If a tag does not serve a clear purpose, do not add it. When in doubt, leave it out.

**Fail:**
```hcl
resource "aws_instance" "web" {
  # ...
  tags = {
    Name        = "web-server"
    Environment = "prod"
    Owner       = "dave@example.com"   # never add this
    CreatedBy   = "terraform"          # not essential — omit
    ManagedBy   = "app-vitals"         # not essential — omit
  }
}
```

**Pass:**
```hcl
resource "aws_instance" "web" {
  # ...
  tags = {
    Name        = "web-server"
    Environment = "prod"
  }
}
```

**Tags that are typically acceptable:**
- `Name` — resource identification
- `Environment` — environment identification (dev, staging, prod)
- Cost-allocation tags required by finance/compliance

**Tags to avoid unless explicitly required:**
- `Owner`, `CreatedBy`, `ManagedBy`, `Team`, `Project` — organizational metadata that belongs in a CMDB, not resource tags

---

## 5. State File Isolation

**Rule:** Dev, staging, and prod environments must use completely separate state files. Never share state across environments.

**Pass — separate backend configs:**
```
environments/
  dev/
    backend.tf     # points to dev state bucket/key
    main.tf
  staging/
    backend.tf     # points to staging state bucket/key
    main.tf
  prod/
    backend.tf     # points to prod state bucket/key
    main.tf
```

**Pass — separate backend config example:**
```hcl
# environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket = "mycompany-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}
```

**Fail — shared state key:**
```hcl
# Used across multiple environments with the same key
terraform {
  backend "s3" {
    bucket = "mycompany-terraform-state"
    key    = "terraform.tfstate"        # no environment isolation
    region = "us-east-1"
  }
}
```

**Fail — single backend.tf at root:**
```
project/
  backend.tf     # one backend for all environments — flag this
  main.tf
  variables.tf
```

**What to flag:**
- Backend configs with no environment differentiation in the key/path
- A single backend.tf shared across environment workspaces without separate state keys
- Any configuration where `terraform state list` could show resources from multiple environments

---

## 6. Module Composition

**Rule:** Prefer small, focused modules over large monolithic ones. A module should do one thing well.

**Flag when a module:**
- Manages more than 2-3 distinct resource types with no clear cohesion
- Exceeds ~200 lines without a clear single responsibility
- Has too many input variables with unrelated concerns

**Fail — monolithic module:**
```hcl
# modules/infrastructure/main.tf (500+ lines)
# Manages VPC, subnets, security groups, EC2 instances,
# RDS databases, S3 buckets, and IAM roles
resource "aws_vpc" "main" { ... }
resource "aws_subnet" "public" { ... }
resource "aws_instance" "web" { ... }
resource "aws_db_instance" "main" { ... }
resource "aws_s3_bucket" "assets" { ... }
resource "aws_iam_role" "app" { ... }
```

**Pass — composable modules:**
```
modules/
  networking/        # VPC, subnets, route tables
    main.tf
    variables.tf
    outputs.tf
  compute/           # EC2 instances, ASGs
    main.tf
    variables.tf
    outputs.tf
  database/          # RDS instances
    main.tf
    variables.tf
    outputs.tf
  storage/           # S3 buckets
    main.tf
    variables.tf
    outputs.tf
```

---

## 7. Variable Validation

**Rule:** All input variables should include explicit `validation` blocks so bad inputs fail fast at plan time.

**Pass:**
```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "instance_type must be a valid AWS instance type (e.g., t3.micro)."
  }
}

variable "port" {
  type        = number
  description = "Application port"

  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "port must be between 1 and 65535."
  }
}
```

**Fail — no validation on constrained input:**
```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"
  # Missing validation — "foobar" would be accepted
}

variable "port" {
  type        = number
  description = "Application port"
  # Missing validation — -1 or 99999 would be accepted
}
```

**When validation is not needed:**
- Boolean variables (only two possible values, enforced by type)
- Variables with `default` values where any value of the correct type is valid
- Free-form string variables (names, descriptions) where no constraint exists

---

## 8. Naming Conventions

**Rule:** Flag obvious violations of consistent naming conventions. Consistency within the codebase is the goal.

**Flag — mixed styles:**
```hcl
# Same file mixes camelCase and snake_case
variable "vpcId" { ... }
variable "subnet_cidr" { ... }
output "securityGroupId" { ... }
output "route_table_id" { ... }
```

**Flag — non-descriptive names:**
```hcl
variable "var1" { ... }
variable "x" { ... }
resource "aws_instance" "thing" { ... }
resource "aws_s3_bucket" "b" { ... }
```

**Flag — inconsistent outputs across modules:**
```hcl
# modules/vpc/outputs.tf
output "vpc_id" { ... }

# modules/compute/outputs.tf
output "instanceId" { ... }   # inconsistent with vpc_id style
```

**Pass — consistent snake_case throughout:**
```hcl
variable "vpc_id" { ... }
variable "subnet_cidr" { ... }
output "security_group_id" { ... }
output "route_table_id" { ... }
resource "aws_instance" "web_server" { ... }
```

**Approach:** Flag clear violations. Do not enforce a strict schema externally — work with whatever convention the codebase has already established. If no convention exists, prefer `snake_case` as the Terraform community standard.
