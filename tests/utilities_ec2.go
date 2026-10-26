package tests

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// PlanExample runs init and plan for an example directory without applying anything.
func PlanExample(t *testing.T, dir string, vars map[string]interface{}) {
	t.Helper()

	options := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: dir,
		Vars:         vars,
		NoColor:      true,
	})

	terraform.InitAndPlan(t, options)
}
