resource "aws_lb" "this" {
  count = var.create_lb ? 1 : 0

  name               = local.load_balancer_name
  load_balancer_type = "application"
  internal           = local.internal
  subnets            = local.lb_subnets
  security_groups    = local.lb_security_groups

  idle_timeout               = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  dynamic "access_logs" {
    for_each = var.lb_access_logs_bucket != null ? [var.lb_access_logs_bucket] : []

    content {
      enabled = true
      bucket  = access_logs.value
      prefix  = var.lb_access_logs_prefix
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.load_balancer_name} LB" },
  )

  lifecycle {
    precondition {
      condition     = length(local.lb_subnets) >= 2
      error_message = "A load balancer needs subnets in at least two availability zones. Set ${var.lb_scheme == "public" ? "public_subnets" : "private_subnets"}, or check that the VPC has subnets named like *-${var.lb_scheme == "public" ? "public" : "private"}-*."
    }
  }
}

resource "aws_lb_target_group" "this" {
  count = var.create_lb ? 1 : 0

  name                 = local.target_group_name
  vpc_id               = local.vpc_id
  target_type          = "instance"
  port                 = var.app_port
  protocol             = var.app_protocol
  deregistration_delay = var.lb_deregistration_delay

  health_check {
    healthy_threshold   = var.healthcheck_healthy_threshold
    unhealthy_threshold = var.healthcheck_unhealthy_threshold
    timeout             = var.healthcheck_timeout
    path                = var.healthcheck_path
    port                = var.healthcheck_port
    protocol            = local.healthcheck_protocol
    interval            = var.healthcheck_interval
    matcher             = var.healthcheck_matcher
  }

  tags = merge(local.tags, { "Name" = "${local.target_group_name} target group" })
}

resource "aws_lb_target_group_attachment" "this" {
  count = var.create_lb ? 1 : 0

  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = aws_instance.this.id
  port             = var.app_port
}

## HTTP listener
resource "aws_lb_listener" "http" {
  count = var.create_lb ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = var.http_port
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = local.http_listener_action == "redirect" ? [1] : []

    content {
      type = "redirect"

      redirect {
        port        = var.https_port
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = local.http_listener_action == "forward" ? [1] : []

    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[0].arn
    }
  }

  # We reject by default, unless one of the application rules below is met.
  dynamic "default_action" {
    for_each = local.http_listener_action == "fixed_response" ? [1] : []

    content {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = var.listener_default_message_body
        status_code  = var.listener_default_status_code
      }
    }
  }

  tags = local.tags
}

## HTTPS listener
resource "aws_lb_listener" "https" {
  count = local.create_https_listener ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = var.https_port
  protocol          = "HTTPS"
  certificate_arn   = local.acm_arn
  ssl_policy        = var.alb_ssl_policy

  dynamic "default_action" {
    for_each = local.listener_default_action == "forward" ? [1] : []

    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[0].arn
    }
  }

  # We reject by default, unless one of the application rules below is met.
  dynamic "default_action" {
    for_each = local.listener_default_action == "fixed_response" ? [1] : []

    content {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = var.listener_default_message_body
        status_code  = var.listener_default_status_code
      }
    }
  }

  tags = local.tags
}

resource "aws_lb_listener_certificate" "extra" {
  for_each = local.create_https_listener ? toset(var.extra_acm_arns) : toset([])

  listener_arn    = aws_lb_listener.https[0].arn
  certificate_arn = each.value
}

## Application rules: forward to the instance when the host header and/or custom headers match
resource "aws_lb_listener_rule" "http_application_rule" {
  for_each = local.http_rules

  listener_arn = aws_lb_listener.http[0].arn
  priority     = var.route_priority + tonumber(each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  dynamic "condition" {
    for_each = each.value != null ? [each.value] : []

    content {
      host_header {
        values = [condition.value]
      }
    }
  }

  dynamic "condition" {
    for_each = var.custom_http_headers

    content {
      http_header {
        http_header_name = condition.value.name
        values           = [condition.value.value]
      }
    }
  }

  tags = local.tags
}

resource "aws_lb_listener_rule" "https_application_rule" {
  for_each = local.https_rules

  listener_arn = aws_lb_listener.https[0].arn
  priority     = var.route_priority + tonumber(each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  dynamic "condition" {
    for_each = each.value != null ? [each.value] : []

    content {
      host_header {
        values = [condition.value]
      }
    }
  }

  dynamic "condition" {
    for_each = var.custom_http_headers

    content {
      http_header {
        http_header_name = condition.value.name
        values           = [condition.value.value]
      }
    }
  }

  tags = local.tags
}
