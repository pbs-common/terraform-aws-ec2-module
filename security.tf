resource "aws_security_group" "this" {
  description = local.security_group_description
  vpc_id      = local.vpc_id
  name        = local.security_group_name
  name_prefix = local.security_group_name_prefix

  tags = merge(
    local.tags,
    { Name = "${local.name} Instance SG" },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  count = var.allow_all_egress ? 1 : 0

  security_group_id = aws_security_group.this.id
  description       = "Allow all traffic out"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "custom" {
  for_each = var.security_group_ingress_rules

  security_group_id            = aws_security_group.this.id
  description                  = coalesce(each.value.description, each.key)
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.protocol == "-1" ? null : each.value.from_port
  to_port                      = each.value.protocol == "-1" ? null : each.value.to_port
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "lb_to_instance" {
  count = var.create_lb ? 1 : 0

  security_group_id            = aws_security_group.this.id
  description                  = "Allow application port traffic from the lb to the instance"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.lb[0].id

  tags = local.tags
}

# Instance -> data store (RDS, ElastiCache, ...): the rule lives on the data store's security group
resource "aws_vpc_security_group_ingress_rule" "data_store" {
  for_each = var.data_store_connections

  security_group_id            = each.value.security_group_id
  description                  = coalesce(each.value.description, "${local.name} to ${each.key}")
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.port
  to_port                      = each.value.port
  referenced_security_group_id = aws_security_group.this.id

  tags = local.tags
}

############################
# Load balancer security group
############################

resource "aws_security_group" "lb" {
  count = var.create_lb ? 1 : 0

  description = local.load_balancer_sg_description
  vpc_id      = local.vpc_id
  name        = local.load_balancer_sg_name
  name_prefix = local.load_balancer_sg_name_prefix

  tags = merge(
    local.tags,
    { Name = "${local.name} LB SG" },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "lb_to_instance" {
  count = var.create_lb ? 1 : 0

  security_group_id            = aws_security_group.lb[0].id
  description                  = "Allow application port traffic from the lb to the instance"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.this.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "user_to_lb_http_cidrs" {
  for_each = var.create_lb ? toset(var.lb_ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.lb[0].id
  description       = "Allow HTTP traffic from the user to the lb for specific CIDRs"
  ip_protocol       = "tcp"
  from_port         = var.http_port
  to_port           = var.http_port
  cidr_ipv4         = each.value

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "user_to_lb_https_cidrs" {
  for_each = local.create_https_listener ? toset(var.lb_ingress_cidr_blocks) : toset([])

  security_group_id = aws_security_group.lb[0].id
  description       = "Allow HTTPS traffic from the user to the lb for specific CIDRs"
  ip_protocol       = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  cidr_ipv4         = each.value

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "user_to_lb_http_prefix_lists" {
  for_each = var.create_lb ? toset(var.lb_ingress_prefix_list_ids) : toset([])

  security_group_id = aws_security_group.lb[0].id
  description       = "Allow HTTP traffic from the user to the lb for specific prefix lists"
  ip_protocol       = "tcp"
  from_port         = var.http_port
  to_port           = var.http_port
  prefix_list_id    = each.value

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "user_to_lb_https_prefix_lists" {
  for_each = local.create_https_listener ? toset(var.lb_ingress_prefix_list_ids) : toset([])

  security_group_id = aws_security_group.lb[0].id
  description       = "Allow HTTPS traffic from the user to the lb for specific prefix lists"
  ip_protocol       = "tcp"
  from_port         = var.https_port
  to_port           = var.https_port
  prefix_list_id    = each.value

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "user_to_lb_http_sg" {
  count = var.create_lb && local.create_sg_access_rule ? 1 : 0

  security_group_id            = aws_security_group.lb[0].id
  description                  = "Allow HTTP traffic from the user to the lb for specific SGs"
  ip_protocol                  = "tcp"
  from_port                    = var.http_port
  to_port                      = var.http_port
  referenced_security_group_id = var.restricted_sg

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "user_to_lb_https_sg" {
  count = local.create_https_listener && local.create_sg_access_rule ? 1 : 0

  security_group_id            = aws_security_group.lb[0].id
  description                  = "Allow HTTPS traffic from the user to the lb for specific SGs"
  ip_protocol                  = "tcp"
  from_port                    = var.https_port
  to_port                      = var.https_port
  referenced_security_group_id = var.restricted_sg

  tags = local.tags
}
