package test

import (
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// requireEnv fails the test with a helpful message when a TF_VAR_* variable the example needs is not set.
func requireEnv(t *testing.T, name string, example string) string {
	t.Helper()

	value := os.Getenv(name)

	if value == "" {
		t.Fatalf("%s must be set to run tests. e.g. 'export %s=%s'", name, name, example)
	}

	return value
}

func testEC2(t *testing.T, variant string, requiredEnv map[string]string) {
	t.Parallel()

	// There is no sensible default AMI for the examples, so the caller supplies one
	for name, example := range requiredEnv {
		requireEnv(t, name, example)
	}

	terraformOptions := &terraform.Options{
		TerraformDir: fmt.Sprintf("../examples/%s", variant),
		LockTimeout:  "5m",
		Vars: map[string]interface{}{
			// Termination and deletion protection are on by default; the tests must be able to clean up
			"deletion_protection": false,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	instanceID := terraform.Output(t, terraformOptions, "instance_id")
	assert.Regexp(t, `^i-[0-9a-f]+$`, instanceID)

	if variant == "alb-waf" {
		assert.NotEmpty(t, terraform.Output(t, terraformOptions, "lb_dns_name"))
		assert.Regexp(t, `^arn:aws[a-z-]*:wafv2:`, terraform.Output(t, terraformOptions, "web_acl_arn"))
	}
}
