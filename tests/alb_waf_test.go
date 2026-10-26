package test

import (
	"testing"
)

func TestAlbWafExample(t *testing.T) {
	testEC2(t, "alb-waf", map[string]string{
		"TF_VAR_ami_id":                  "ami-0123456789abcdef0",
		"TF_VAR_hosted_zone":             "example.org",
		"TF_VAR_rds_security_group_id":   "sg-0123456789abcdef0",
		"TF_VAR_cache_security_group_id": "sg-0123456789abcdef0",
		"TF_VAR_bucket_arn":              "arn:aws:s3:::example-bucket",
		"TF_VAR_assets_bucket_arn":       "arn:aws:s3:::example-assets-bucket",
	})
}
