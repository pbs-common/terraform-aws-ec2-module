############################
# WAF
############################

variable "create_waf" {
  description = "(optional) Create a regional WAFv2 web ACL and attach it to the load balancer. Requires create_lb"
  default     = false
  type        = bool
  validation {
    condition     = !var.create_waf || var.create_lb
    error_message = "create_waf requires create_lb to be true."
  }
}

variable "web_acl_arn" {
  description = "(optional) ARN of an existing regional web ACL to attach to the load balancer instead of creating one. Requires create_lb and cannot be combined with create_waf"
  default     = null
  type        = string
  validation {
    condition     = var.web_acl_arn == null || (var.create_lb && !var.create_waf)
    error_message = "web_acl_arn requires create_lb and cannot be combined with create_waf."
  }
}

variable "waf_default_action" {
  description = "(optional) Default action of the created web ACL: allow or block"
  default     = "allow"
  type        = string
  validation {
    condition     = contains(["allow", "block"], var.waf_default_action)
    error_message = "The waf_default_action variable must be allow or block."
  }
}

variable "waf_managed_rule_groups" {
  description = "(optional) Managed rule groups in the created web ACL, evaluated in list order. rules_to_count switches individual rules to count-only"
  default = [
    { name = "AWSManagedRulesCommonRuleSet" },
    { name = "AWSManagedRulesKnownBadInputsRuleSet" },
    { name = "AWSManagedRulesAmazonIpReputationList" },
  ]
  type = list(object({
    name           = string
    vendor_name    = optional(string, "AWS")
    rules_to_count = optional(list(string), [])
  }))
}

variable "waf_rate_limit" {
  description = "(optional) Block IPs exceeding this many requests per 5 minutes in the created web ACL. Null disables the rate rule"
  default     = null
  type        = number
  validation {
    condition     = var.waf_rate_limit == null || coalesce(var.waf_rate_limit, 100) >= 10
    error_message = "The waf_rate_limit variable must be at least 10."
  }
}

variable "waf_log_destination_arn" {
  description = "(optional) ARN of a CloudWatch log group, S3 bucket or Firehose stream (name starting aws-waf-logs-) for web ACL logs. Null disables logging"
  default     = null
  type        = string
}
