locals {
  name    = var.name != null ? var.name : var.product
  creator = "terraform"

  defaulted_tags = merge(
    var.tags,
    {
      Name                                      = local.name
      "${var.organization}:billing:product"     = var.product
      "${var.organization}:billing:environment" = var.environment
      "${var.organization}:billing:owner"       = var.owner
      creator                                   = local.creator
      repo                                      = var.repo
    }
  )

  tags = merge({ for k, v in local.defaulted_tags : k => v if lookup(data.aws_default_tags.common_tags.tags, k, "") != v })

  # Network. An explicit vpc_id wins, then the VPC of a supplied subnet, then the environment-tag lookup.
  vpc_id    = var.vpc_id != null ? var.vpc_id : var.subnet_id != null ? one(data.aws_subnet.supplied[*].vpc_id) : one(data.aws_vpc.vpc[*].id)
  subnet_id = var.subnet_id != null ? var.subnet_id : try(sort(data.aws_subnets.instance[0].ids)[0], null)

  public_subnets  = var.public_subnets != null ? var.public_subnets : try(data.aws_subnets.lb_public[0].ids, [])
  private_subnets = var.private_subnets != null ? var.private_subnets : try(data.aws_subnets.lb_private[0].ids, [])
  lb_subnets      = var.lb_scheme == "public" ? local.public_subnets : local.private_subnets
  internal        = var.internal != null ? var.internal : var.lb_scheme == "internal"
  public_service  = var.lb_scheme == "public"

  # Names. Load balancer and target group names are limited to 32 characters and cannot end in a hyphen.
  load_balancer_name = var.load_balancer_name != null ? var.load_balancer_name : trimsuffix(substr(local.name, 0, 32), "-")
  target_group_name  = var.target_group_name != null ? var.target_group_name : trimsuffix(substr(local.name, 0, 32), "-")

  # Security group names. A security group takes either a generated-with-suffix name or an exact
  # one, never both, so the two modes are mutually exclusive and one side is always null.
  security_group_name_base     = var.security_group_name != null ? var.security_group_name : "${local.name}-sg${var.use_sg_name_prefix ? "-" : ""}"
  load_balancer_sg_name_base   = var.load_balancer_sg_name != null ? var.load_balancer_sg_name : "${local.load_balancer_name}-lb-sg${var.use_sg_name_prefix ? "-" : ""}"
  security_group_name          = var.use_sg_name_prefix ? null : local.security_group_name_base
  security_group_name_prefix   = var.use_sg_name_prefix ? local.security_group_name_base : null
  security_group_description   = var.security_group_description != null ? var.security_group_description : "Controls access to the ${local.name} instance"
  load_balancer_sg_name        = var.use_sg_name_prefix ? null : local.load_balancer_sg_name_base
  load_balancer_sg_name_prefix = var.use_sg_name_prefix ? local.load_balancer_sg_name_base : null
  load_balancer_sg_description = var.load_balancer_sg_description != null ? var.load_balancer_sg_description : "Controls access to the ${local.name} load balancer"
  create_sg_access_rule        = var.restricted_sg != null
  lb_security_groups           = var.create_lb ? concat([one(aws_security_group.lb[*].id)], var.extra_lb_security_group_ids) : null
  healthcheck_protocol         = var.healthcheck_protocol != null ? var.healthcheck_protocol : var.app_protocol

  # DNS and certificates. Records are only created when a hosted zone is given.
  cnames                           = var.cnames != null ? var.cnames : var.hosted_zone != null ? [local.name] : []
  aliases                          = var.aliases != null ? var.aliases : var.hosted_zone != null ? ["${local.name}.${var.hosted_zone}"] : []
  app_dns_record_count             = var.create_lb && var.hosted_zone != null ? length(local.cnames) : 0
  lookup_hosted_zone               = local.app_dns_record_count > 0
  lookup_primary_acm_wildcard_cert = local.lookup_hosted_zone && local.public_service && var.acm_arn == null
  acm_arn                          = var.acm_arn != null ? var.acm_arn : local.lookup_primary_acm_wildcard_cert ? one(data.aws_acm_certificate.primary_acm_wildcard_cert[*].arn) : null
  hosted_zone_id                   = local.lookup_hosted_zone ? one(data.aws_route53_zone.hosted_zone[*].zone_id) : null
  domain_name                      = !var.create_lb ? null : local.app_dns_record_count == 0 ? aws_lb.this[0].dns_name : aws_route53_record.app[0].fqdn

  # Listeners. When there is something to match on (host header aliases or custom headers) the
  # listeners reject by default and forward only through rules, like the ECS service module.
  # With nothing to match on there is nothing to restrict by, so they forward.
  create_https_listener   = var.create_lb && local.acm_arn != null
  has_rule_conditions     = (var.listener_rule_host_header && length(local.aliases) > 0) || length(var.custom_http_headers) > 0
  listener_default_action = var.listener_default_action != null ? var.listener_default_action : local.has_rule_conditions ? "fixed_response" : "forward"
  http_listener_action    = local.create_https_listener && var.http_redirect ? "redirect" : local.listener_default_action

  # One rule per alias when matching on host header, otherwise a single rule matching on the
  # custom headers alone: repeating a header-only rule per alias would just duplicate it.
  rule_aliases = var.listener_rule_host_header && length(local.aliases) > 0 ? local.aliases : [null]
  rules        = { for i, a in local.rule_aliases : tostring(i) => a }
  http_rules   = var.create_lb && local.has_rule_conditions && local.http_listener_action == "fixed_response" ? local.rules : {}
  https_rules  = local.create_https_listener && local.has_rule_conditions && local.listener_default_action == "fixed_response" ? local.rules : {}

  attach_web_acl = var.create_lb && (var.create_waf || var.web_acl_arn != null)

  # Secrets split by backend: Secrets Manager values are ARNs, everything else is an SSM parameter name
  secrets_manager_secrets = { for k, v in var.secrets : k => v if startswith(v, "arn:") }
  ssm_secrets             = { for k, v in var.secrets : k => v if !startswith(v, "arn:") }

  ssm_secret_arns = [
    for v in values(local.ssm_secrets) :
    "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${startswith(v, "/") ? v : "/${v}"}"
  ]

  ssm_path_arns = flatten([
    for p in var.ssm_parameter_paths : [
      "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${trimsuffix(p, "/")}",
      "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${trimsuffix(p, "/")}/*",
    ]
  ])

  secrets_manager_arns = concat(var.secrets_manager_arns, values(local.secrets_manager_secrets))
  ssm_read_arns        = concat(local.ssm_secret_arns, local.ssm_path_arns)

  # The inline policy is only created when something feeds it; an empty policy document is invalid
  has_inline_policy = anytrue([
    var.extra_role_policy_json != null,
    length(var.s3_bucket_arns) > 0,
    length(var.s3_read_only_bucket_arns) > 0,
    length(local.secrets_manager_arns) > 0,
    length(local.ssm_read_arns) > 0,
    length(var.kms_key_arns) > 0,
    length(var.sqs_queue_arns) > 0,
    length(var.sns_topic_arns) > 0,
    length(var.dynamodb_table_arns) > 0,
  ])

  # User data is only generated when there is something to write; instances without user data stay null
  use_env_bootstrap = length(var.environment_variables) > 0 || length(var.secrets) > 0

  user_data = local.use_env_bootstrap ? join("\n", compact([
    templatefile("${path.module}/templates/env-bootstrap.sh.tftpl", {
      region                  = data.aws_region.current.region
      environment_variables   = var.environment_variables
      ssm_secrets             = local.ssm_secrets
      secrets_manager_secrets = local.secrets_manager_secrets
    }),
    var.user_data != null ? replace(var.user_data, "/^#![^\\n]*\\n/", "") : null,
  ])) : var.user_data
}

data "aws_default_tags" "common_tags" {}
