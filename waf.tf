resource "aws_wafv2_web_acl" "this" {
  count = var.create_waf ? 1 : 0

  name        = local.name
  description = "Web ACL for the ${local.name} ALB"
  scope       = "REGIONAL"

  default_action {
    dynamic "allow" {
      for_each = var.waf_default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.waf_default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "rule" {
    for_each = var.waf_rate_limit != null ? [var.waf_rate_limit] : []

    content {
      name     = "rate-limit"
      priority = 1

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = rule.value
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = "${local.name}-rate-limit"
      }
    }
  }

  dynamic "rule" {
    for_each = { for i, g in var.waf_managed_rule_groups : tostring(i) => g }

    content {
      name     = rule.value.name
      priority = (tonumber(rule.key) + 1) * 10

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name

          dynamic "rule_action_override" {
            for_each = rule.value.rules_to_count

            content {
              name = rule_action_override.value

              action_to_use {
                count {}
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = "${local.name}-${rule.value.name}"
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = local.name
  }

  tags = local.tags
}

resource "aws_wafv2_web_acl_association" "this" {
  count = local.attach_web_acl ? 1 : 0

  resource_arn = aws_lb.this[0].arn
  web_acl_arn  = coalesce(var.web_acl_arn, one(aws_wafv2_web_acl.this[*].arn))
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.create_waf && var.waf_log_destination_arn != null ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.this[0].arn
  log_destination_configs = [var.waf_log_destination_arn]
}
