data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

# VPC lookup, same convention as the ECS service module: the Name tag contains the environment.
# Only runs when neither vpc_id nor subnet_id is given; a supplied subnet already says which VPC.
data "aws_vpc" "vpc" {
  count = var.vpc_id == null && var.subnet_id == null ? 1 : 0
  tags = {
    "Name" : "*${var.environment}*"
  }
}

data "aws_subnet" "supplied" {
  count = var.subnet_id != null ? 1 : 0

  id = var.subnet_id
}

# The instance's subnet when subnet_id is null: the first (by ID) subnet matching the
# private/public naming convention, optionally restricted to one availability zone.
data "aws_subnets" "instance" {
  count = var.subnet_id == null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = [var.instance_subnet_scheme == "public" ? "*-public-*" : "*-private-*"]
  }

  dynamic "filter" {
    for_each = var.availability_zone != null ? [var.availability_zone] : []

    content {
      name   = "availability-zone"
      values = [filter.value]
    }
  }
}

# The chosen subnet, read for its availability zone (additional EBS volumes must match it)
data "aws_subnet" "selected" {
  id = local.subnet_id

  lifecycle {
    precondition {
      condition     = local.subnet_id != null
      error_message = "No subnet was found for the instance. Set subnet_id, or check that ${local.vpc_id} has ${var.instance_subnet_scheme} subnets named like *-${var.instance_subnet_scheme}-*${var.availability_zone != null ? " in ${var.availability_zone}" : ""}."
    }
  }
}

# Load balancer subnets, only looked up when they are not given
data "aws_subnets" "lb_public" {
  count = var.create_lb && var.lb_scheme == "public" && var.public_subnets == null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*-public-*"]
  }
}

data "aws_subnets" "lb_private" {
  count = var.create_lb && var.lb_scheme == "internal" && var.private_subnets == null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*-private-*"]
  }
}

data "aws_route53_zone" "hosted_zone" {
  count = local.lookup_hosted_zone ? 1 : 0

  name         = "${var.hosted_zone}."
  private_zone = var.is_hosted_zone_private
}

data "aws_acm_certificate" "primary_acm_wildcard_cert" {
  count = local.lookup_primary_acm_wildcard_cert ? 1 : 0

  domain = "*.${var.hosted_zone}"
}
