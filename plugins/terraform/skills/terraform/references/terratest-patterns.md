# Terratest Patterns

Patterns and boilerplate for generating [Terratest](https://terratest.gruntwork.io/) tests alongside Terraform modules. Generate both unit and integration tests automatically when creating or modifying Terraform code.

---

## File Placement

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
      go.mod
      go.sum
```

Each `test/` directory needs its own `go.mod`:

```go
module github.com/example/modules/vpc/test

go 1.21

require (
    github.com/gruntwork-io/terratest v0.47.2
    github.com/stretchr/testify v1.9.0
)
```

---

## Unit Test Pattern

Unit tests validate the Terraform plan output without applying resources. Fast, safe, and suitable for CI.

```go
package test

import (
    "testing"

    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVpcUnit(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../",
        Vars: map[string]interface{}{
            "vpc_cidr":     "10.0.0.0/16",
            "environment":  "dev",
            "az_count":     2,
        },
        // Plan only — do not apply
        PlanFilePath: "tfplan",
    })

    // Run terraform init and plan
    plan := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

    // Validate resource counts
    assert.Equal(t, 1, len(plan.ResourcePlannedValuesMap["aws_vpc.main"]))

    // Validate planned values
    vpc := plan.ResourcePlannedValuesMap["aws_vpc.main"][0]
    assert.Equal(t, "10.0.0.0/16", vpc.AttributeValues["cidr_block"])

    // Validate tags
    tags := vpc.AttributeValues["tags"].(map[string]interface{})
    assert.Equal(t, "dev", tags["Environment"])
    assert.NotContains(t, tags, "Owner", "Owner tag must not be present")
}
```

### Unit Test Checklist

When generating unit tests, validate:
- [ ] Expected resource count in the plan
- [ ] Planned attribute values match inputs
- [ ] Tags conform to conservative tagging rules (no `owner`)
- [ ] Variable validation blocks reject bad inputs
- [ ] Module outputs are present and correctly typed
- [ ] No unexpected resource changes (for modification tests)

---

## Integration Test Pattern

Integration tests apply the configuration to real infrastructure and validate behavior. Slower, requires cloud credentials, best for pre-merge validation.

```go
package test

import (
    "testing"

    "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVpcIntegration(t *testing.T) {
    t.Parallel()

    awsRegion := aws.GetRandomStableRegion(t, nil, nil)

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../",
        Vars: map[string]interface{}{
            "vpc_cidr":     "10.0.0.0/16",
            "environment":  "test",
            "az_count":     2,
        },
        EnvVars: map[string]string{
            "AWS_DEFAULT_REGION": awsRegion,
        },
    })

    // Clean up resources after test
    defer terraform.Destroy(t, terraformOptions)

    // Apply the Terraform code
    terraform.InitAndApply(t, terraformOptions)

    // Retrieve outputs
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)

    // Validate the VPC exists and has correct CIDR
    vpc := aws.GetVpcById(t, vpcId, awsRegion)
    assert.Equal(t, "10.0.0.0/16", vpc.CidrBlock)

    // Validate subnets were created
    subnets := aws.GetSubnetsForVpc(t, vpcId, awsRegion)
    assert.Equal(t, 2, len(subnets))

    // Validate tags on real resources
    tags := aws.GetTagsForVpc(t, vpcId, awsRegion)
    assert.Equal(t, "test", tags["Environment"])
    assert.NotContains(t, tags, "Owner")
}
```

### Integration Test Checklist

When generating integration tests, validate:
- [ ] Resources are created successfully (`InitAndApply` succeeds)
- [ ] `defer terraform.Destroy` is always present for cleanup
- [ ] Outputs match expected values
- [ ] Real resource attributes match configuration
- [ ] Cross-resource relationships work (e.g., subnets in correct VPC)
- [ ] Tags on real resources conform to conservative tagging rules
- [ ] Networking connectivity where applicable (security groups, routes)

---

## Test Naming Conventions

Follow consistent naming for generated test files:

| Module | Unit Test | Integration Test |
|--------|-----------|------------------|
| `vpc` | `vpc_unit_test.go` | `vpc_integration_test.go` |
| `compute` | `compute_unit_test.go` | `compute_integration_test.go` |
| `database` | `database_unit_test.go` | `database_integration_test.go` |
| `networking` | `networking_unit_test.go` | `networking_integration_test.go` |

Test function names: `TestVpcUnit`, `TestVpcIntegration`, `TestComputeUnit`, etc.

---

## Common Terratest Helpers

### Testing Variable Validation

Verify that invalid inputs are rejected at plan time:

```go
func TestVpcInvalidEnvironment(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../",
        Vars: map[string]interface{}{
            "vpc_cidr":    "10.0.0.0/16",
            "environment": "invalid-env",  // should fail validation
            "az_count":    2,
        },
    })

    // Expect plan to fail due to validation
    _, err := terraform.InitAndPlanE(t, terraformOptions)
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "environment must be one of")
}
```

### Testing Module Outputs

Validate all outputs are present and correctly typed:

```go
func TestVpcOutputs(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../",
        Vars: map[string]interface{}{
            "vpc_cidr":    "10.0.0.0/16",
            "environment": "dev",
            "az_count":    2,
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Validate all expected outputs exist
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)

    subnetIds := terraform.OutputList(t, terraformOptions, "subnet_ids")
    assert.Equal(t, 2, len(subnetIds))

    cidrBlock := terraform.Output(t, terraformOptions, "cidr_block")
    assert.Equal(t, "10.0.0.0/16", cidrBlock)
}
```

---

## Provider-Specific Patterns

### AWS

Use `github.com/gruntwork-io/terratest/modules/aws` for AWS resource validation:
- `aws.GetVpcById` — validate VPC attributes
- `aws.GetSubnetsForVpc` — validate subnet creation
- `aws.GetTagsForVpc` — validate tag compliance
- `aws.GetRandomStableRegion` — randomize region for isolation

### GCP

Use `github.com/gruntwork-io/terratest/modules/gcp`:
- `gcp.GetProject` — validate project settings
- `gcp.GetRandomRegion` — randomize region

### Azure

Use `github.com/gruntwork-io/terratest/modules/azure`:
- `azure.GetResourceGroup` — validate resource groups
- `azure.GetVirtualNetwork` — validate VNet configuration

---

## CI Integration

For unit tests (plan-only), include in every PR pipeline:

```yaml
# .github/workflows/terraform-test.yml
- name: Run Terratest unit tests
  run: |
    cd modules/vpc/test
    go test -v -run "Unit" -timeout 10m
```

For integration tests, run on a schedule or pre-merge to main:

```yaml
- name: Run Terratest integration tests
  run: |
    cd modules/vpc/test
    go test -v -run "Integration" -timeout 30m
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```
