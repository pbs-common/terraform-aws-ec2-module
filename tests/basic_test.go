package test

import (
	"testing"
)

func TestBasicExample(t *testing.T) {
	testEC2(t, "basic", map[string]string{
		"TF_VAR_ami_id": "ami-0123456789abcdef0",
	})
}
