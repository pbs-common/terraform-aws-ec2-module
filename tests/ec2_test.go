package tests

import "testing"

func TestBasicExamplePlans(t *testing.T) {
	PlanExample(t, "../examples/basic", map[string]interface{}{
		"ami_id": "ami-0123456789abcdef0",
	})
}
