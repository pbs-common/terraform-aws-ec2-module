############################
# Load balancer
############################

variable "create_lb" {
  description = "(optional) Create an Application Load Balancer and target group in front of the instance"
  default     = false
  type        = bool
}

variable "load_balancer_name" {
  description = "(optional) Load balancer name, max 32 characters. Will default to the module name truncated to 32 if not defined."
  default     = null
  type        = string
}

variable "target_group_name" {
  description = "(optional) Target group name, max 32 characters. Will default to the module name truncated to 32 if not defined."
  default     = null
  type        = string
}

variable "lb_scheme" {
  description = "(optional) Scheme for the load balancer and its subnet selection. \"public\" creates an internet-facing LB in public subnets. \"internal\" creates an internal LB in private subnets."
  default     = "public"
  type        = string
  validation {
    condition     = contains(["public", "internal"], var.lb_scheme)
    error_message = "lb_scheme must be either \"public\" or \"internal\"."
  }
}

variable "internal" {
  description = "(optional) Use an internal load balancer. If null, will be internal when lb_scheme is internal."
  default     = null
  type        = bool
}

variable "private_subnets" {
  description = "(optional) Private subnets for an internal load balancer (at least two availability zones). If null, they are looked up in the VPC by name (*-private-*). Not used for the instance: see subnet_id"
  default     = null
  type        = list(string)
}

variable "public_subnets" {
  description = "(optional) Public subnets for an internet-facing load balancer (at least two availability zones). If null, they are looked up in the VPC by name (*-public-*). Not used for the instance: see subnet_id"
  default     = null
  type        = list(string)
}

variable "lb_ingress_cidr_blocks" {
  description = "(optional) CIDR blocks allowed to reach the load balancer (HTTP/HTTPS ingress). Defaults to open internet access."
  default     = ["0.0.0.0/0"]
  type        = list(string)
}

variable "lb_ingress_prefix_list_ids" {
  description = "(optional) Prefix lists allowed to reach the load balancer (HTTP/HTTPS ingress)"
  default     = []
  type        = list(string)
}

variable "restricted_sg" {
  description = "(optional) SG allowed to reach the load balancer, in addition to lb_ingress_cidr_blocks. If null, no sg will be configured to connect"
  default     = null
  type        = string
}

variable "extra_lb_security_group_ids" {
  description = "(optional) List of additional security group IDs to attach to the load balancer, alongside the module-managed load balancer security group. Ignored when no load balancer is created."
  default     = []
  type        = list(string)
}

variable "idle_timeout" {
  description = "(optional) Idle timeout for the load balancer. If null, will use whatever the default is for the load balancer."
  default     = null
  type        = number
}

variable "enable_deletion_protection" {
  description = "(optional) Protect the load balancer from deletion. On by default: set to false before destroying the load balancer"
  default     = true
  type        = bool
}

variable "lb_access_logs_bucket" {
  description = "(optional) S3 bucket name for load balancer access logs. Null disables access logs"
  default     = null
  type        = string
}

variable "lb_access_logs_prefix" {
  description = "(optional) Key prefix for load balancer access logs"
  default     = null
  type        = string
}

variable "http_port" {
  description = "(optional) HTTP port number."
  default     = 80
  type        = number
}

variable "https_port" {
  description = "(optional) HTTPS port number."
  default     = 443
  type        = number
}

variable "http_redirect" {
  description = "(optional) Redirect HTTP traffic to HTTPS. If set to false, the HTTP listener behaves like the HTTPS one. Only applies when there is an HTTPS listener"
  default     = true
  type        = bool
}

variable "acm_arn" {
  description = "(optional) ARN of the ACM certificate for the HTTPS listener. If null and hosted_zone is set on a public load balancer, the wildcard certificate of the hosted zone is looked up. If still null, only an HTTP listener is created"
  default     = null
  type        = string
}

variable "extra_acm_arns" {
  description = "(optional) List of additional ACM certificate ARNs to attach to the HTTPS listener."
  default     = []
  type        = list(string)
}

variable "alb_ssl_policy" {
  description = "(optional) SSL policy to use for the HTTPS listener."
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  type        = string
}

variable "listener_default_action" {
  description = "(optional) What the listeners do with requests that match no rule: `fixed_response` or `forward`. When null: `fixed_response` if there are host header aliases or custom_http_headers to match on, otherwise `forward`"
  default     = null
  type        = string
  validation {
    condition     = var.listener_default_action == null || contains(["fixed_response", "forward"], coalesce(var.listener_default_action, "forward"))
    error_message = "The listener_default_action must be `fixed_response` or `forward`."
  }
}

variable "listener_default_status_code" {
  description = "(optional) HTTP status code returned by the default fixed-response action of the listeners. Requests that match no listener rule get this."
  default     = "403"
  type        = string
  validation {
    condition     = can(regex("^[2-5][0-9][0-9]$", var.listener_default_status_code))
    error_message = "The listener_default_status_code must be a three-digit HTTP status code between 200 and 599."
  }
}

variable "listener_default_message_body" {
  description = "(optional) Body returned with the listeners' default fixed response. Null sends an empty body."
  default     = null
  type        = string
}

variable "listener_rule_host_header" {
  description = "(optional) Match the aliases with a `host_header` condition on the listener rules. Set to false to route on `custom_http_headers` alone, for an instance reachable only through a CDN that injects a shared secret header, say. With this false a single rule is created per listener instead of one per alias"
  default     = true
  type        = bool
}

variable "custom_http_headers" {
  description = "(optional) Custom HTTP headers a request must carry to be forwarded. Format should be a list of maps with `name` and `value` keys. e.g. [{ name = \"header1\", value = \"value1\"}]"
  default     = []
  type        = list(object({ name = string, value = string }))
}

variable "route_priority" {
  description = "(optional) Starting route priority, incremented by each listener rule"
  default     = 10
  type        = number
}

variable "hosted_zone" {
  description = "(optional) Name of the hosted zone for DNS. e.g. hosted_zone = example.org --> service.example.org. Based on is_hosted_zone_private, this is the primary or the private hosted zone. If null, no DNS records are created"
  default     = null
  type        = string
}

variable "is_hosted_zone_private" {
  description = "(optional) Is the route53 zone private or not."
  default     = false
  type        = bool
}

variable "cnames" {
  description = "(optional) CNAME(s) that are going to be created for the load balancer in the hosted_zone. This can be set to [] to avoid creating a CNAME, which can be useful for CDNs. Default is `name` when hosted_zone is set. e.g. [name] --> [name.example.com]"
  default     = null
  type        = list(string)
}

variable "aliases" {
  description = "(optional) CNAME(s) that are allowed to be used for this instance, matched as host headers by the listener rules. Default is `name`.`hosted_zone` when hosted_zone is set. e.g. [name.example.com]"
  default     = null
  type        = list(string)
}

variable "dns_evaluate_target_health" {
  description = "(optional) Evaluate health of endpoints by querying DNS records"
  default     = false
  type        = bool
}

variable "app_port" {
  description = "(optional) Port the application listens on inside the instance. The load balancer forwards to it and the instance security group allows the load balancer on it"
  default     = 80
  type        = number
  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "The app_port variable must be between 1 and 65535."
  }
}

variable "app_protocol" {
  description = "(optional) Protocol the load balancer uses to talk to the application: HTTP or HTTPS"
  default     = "HTTP"
  type        = string
  validation {
    condition     = contains(["HTTP", "HTTPS"], var.app_protocol)
    error_message = "The app_protocol variable must be HTTP or HTTPS."
  }
}

variable "healthcheck_path" {
  description = "(optional) The destination for the health check request. Null uses the AWS default (/)"
  default     = null
  type        = string
}

variable "healthcheck_port" {
  description = "(optional) The port used for health checks: a port number or traffic-port"
  default     = "traffic-port"
  type        = string
}

variable "healthcheck_protocol" {
  description = "(optional) The protocol to use to connect with the target. Null uses app_protocol"
  default     = null
  type        = string
}

variable "healthcheck_matcher" {
  description = "(optional) The HTTP codes to use when checking for a successful response from a target"
  default     = "200"
  type        = string
}

variable "healthcheck_interval" {
  description = "(optional) The approximate amount of time, in seconds, between health checks of the target"
  default     = 10
  type        = number
}

variable "healthcheck_timeout" {
  description = "(optional) The amount of time, in seconds, during which no response means a failed health check"
  default     = 6
  type        = number
}

variable "healthcheck_healthy_threshold" {
  description = "(optional) The number of consecutive health check successes required before considering an unhealthy target healthy"
  default     = 3
  type        = number
}

variable "healthcheck_unhealthy_threshold" {
  description = "(optional) The number of consecutive health check failures required before considering the target unhealthy"
  default     = 3
  type        = number
}

variable "lb_deregistration_delay" {
  description = "(optional) Seconds the target group waits before deregistering the instance"
  default     = 30
  type        = number
}
