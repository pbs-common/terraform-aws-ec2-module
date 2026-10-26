############################
# Instance
############################

variable "name" {
  description = "(optional) Name of the instance and prefix for related resources (defaults to product if null)"
  default     = null
  type        = string
}

variable "key_name" {
  description = "(optional) Name of an existing EC2 key pair. Leave null and use SSM Session Manager where possible"
  default     = null
  type        = string
}

variable "private_ip" {
  description = "(optional) Fixed private IPv4 address inside the subnet. Null lets AWS choose"
  default     = null
  type        = string
}

variable "associate_public_ip_address" {
  description = "(optional) Associate a public IPv4 address with the instance"
  default     = false
  type        = bool
}

variable "source_dest_check" {
  description = "(optional) Enable the source/destination check (disable only for NAT/proxy instances)"
  default     = true
  type        = bool
}

variable "ebs_optimized" {
  description = "(optional) Launch as EBS-optimized. Null uses the instance type default"
  default     = null
  type        = bool
}

variable "monitoring" {
  description = "(optional) Enable detailed (1 minute) CloudWatch monitoring"
  default     = false
  type        = bool
}

variable "cpu_credits" {
  description = "(optional) CPU credit mode for burstable (t2/t3/t3a/t4g) instances: standard or unlimited. Null keeps the AWS default"
  default     = null
  type        = string
  validation {
    condition     = var.cpu_credits == null || contains(["standard", "unlimited"], coalesce(var.cpu_credits, "standard"))
    error_message = "The cpu_credits variable must be null, standard or unlimited."
  }
}

variable "disable_api_termination" {
  description = "(optional) EC2 termination protection. On by default: set to false before destroying the instance"
  default     = true
  type        = bool
}

variable "disable_api_stop" {
  description = "(optional) Enable EC2 stop protection"
  default     = false
  type        = bool
}

variable "instance_initiated_shutdown_behavior" {
  description = "(optional) What happens when the OS shuts down: stop or terminate"
  default     = "stop"
  type        = string
  validation {
    condition     = contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "The instance_initiated_shutdown_behavior variable must be stop or terminate."
  }
}

variable "imds_http_tokens" {
  description = "(optional) Instance metadata service version: required enforces IMDSv2 (PBS standard)"
  default     = "required"
  type        = string
  validation {
    condition     = contains(["required", "optional"], var.imds_http_tokens)
    error_message = "The imds_http_tokens variable must be required or optional."
  }
}

variable "imds_hop_limit" {
  description = "(optional) IMDS PUT response hop limit. Raise to 2 if containers on the instance need the metadata service"
  default     = 1
  type        = number
  validation {
    condition     = var.imds_hop_limit >= 1 && var.imds_hop_limit <= 64
    error_message = "The imds_hop_limit variable must be between 1 and 64."
  }
}

############################
# Network
############################

variable "vpc_id" {
  description = "(optional) VPC ID. If null, the VPC of subnet_id is used; if that is null too, one will be looked up based on environment tag."
  default     = null
  type        = string
  validation {
    condition     = var.vpc_id == null || can(regex("^vpc-[0-9a-f]+$", coalesce(var.vpc_id, "x")))
    error_message = "The vpc_id variable must look like vpc-0123456789abcdef0."
  }
}

variable "subnet_id" {
  description = "(optional) Subnet the instance is launched in. If null, one is looked up in the VPC by name (*-private-* or *-public-*, see instance_subnet_scheme), optionally restricted to availability_zone"
  default     = null
  type        = string
  validation {
    condition     = var.subnet_id == null || can(regex("^subnet-[0-9a-f]+$", coalesce(var.subnet_id, "x")))
    error_message = "The subnet_id variable must look like subnet-0123456789abcdef0."
  }
}

variable "availability_zone" {
  description = "(optional) Availability zone to place the instance in when subnet_id is null, e.g. us-east-1a. Ignored when subnet_id is set. If null, the first matching subnet by ID is used"
  default     = null
  type        = string
}

variable "instance_subnet_scheme" {
  description = "(optional) Subnet placement when subnet_id is null. \"private\" (default) uses *-private-* subnets, \"public\" uses *-public-* subnets"
  default     = "private"
  type        = string
  validation {
    condition     = contains(["private", "public"], var.instance_subnet_scheme)
    error_message = "instance_subnet_scheme must be either \"private\" or \"public\"."
  }
}

############################
# Storage
############################

variable "root_volume" {
  description = "(optional) Root EBS volume settings. Encrypted by default (PBS standard); set encrypted = false only to mirror an existing unencrypted volume"
  default     = {}
  type = object({
    size                  = optional(number, 30)
    type                  = optional(string, "gp3")
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool, true)
    kms_key_id            = optional(string)
    delete_on_termination = optional(bool, true)
  })
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "standard"], var.root_volume.type)
    error_message = "The root_volume.type must be one of [gp2, gp3, io1, io2, standard]."
  }
}

variable "additional_ebs_volumes" {
  description = "(optional) Extra EBS volumes keyed by a short name (used in the Name tag). Set volume_id to attach an existing volume instead of creating one, snapshot_id to restore from a snapshot. Volumes are always attached with a separate attachment so they survive instance replacement"
  default     = {}
  type = map(object({
    device_name    = string
    size           = optional(number)
    type           = optional(string, "gp3")
    iops           = optional(number)
    throughput     = optional(number)
    encrypted      = optional(bool, true)
    kms_key_id     = optional(string)
    snapshot_id    = optional(string)
    volume_id      = optional(string)
    final_snapshot = optional(bool, true)
  }))
  validation {
    condition = alltrue([
      for v in values(var.additional_ebs_volumes) :
      contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], v.type)
    ])
    error_message = "Each additional_ebs_volumes type must be one of [gp2, gp3, io1, io2, st1, sc1, standard]."
  }
  validation {
    condition = alltrue([
      for v in values(var.additional_ebs_volumes) :
      v.volume_id != null || v.size != null || v.snapshot_id != null
    ])
    error_message = "Each additional_ebs_volumes entry needs one of volume_id, size or snapshot_id."
  }
}

############################
# Security groups
############################

variable "extra_security_group_ids" {
  description = "(optional) List of additional security group IDs to attach to the instance, alongside the module-managed security group"
  default     = []
  type        = list(string)
}

variable "security_group_ingress_rules" {
  description = "(optional) Extra ingress rules on the module-created instance security group, keyed by a unique name. Exactly one source per rule: cidr_ipv4, cidr_ipv6, prefix_list_id or referenced_security_group_id. Use protocol = \"-1\" for all traffic (ports are then ignored)"
  default     = {}
  type = map(object({
    description                  = optional(string)
    protocol                     = optional(string, "tcp")
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
  }))
  validation {
    condition = alltrue([
      for r in values(var.security_group_ingress_rules) :
      length([for s in [r.cidr_ipv4, r.cidr_ipv6, r.prefix_list_id, r.referenced_security_group_id] : s if s != null]) == 1
    ])
    error_message = "Each security_group_ingress_rules entry must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, referenced_security_group_id."
  }
}

variable "allow_all_egress" {
  description = "(optional) Allow all outbound traffic from the module-created instance security group"
  default     = true
  type        = bool
}

variable "security_group_name" {
  description = "(optional) Name of the instance security group. Used as a prefix unless `use_sg_name_prefix` is false. If null, will use `$${local.name}-sg-` (prefix) or `$${local.name}-sg` (exact name)."
  default     = null
  type        = string
}

variable "security_group_description" {
  description = "(optional) Description for the instance security group. Defaults to `Controls access to the <name> instance`. `description` is ForceNew on aws_security_group, so match an existing group's description to adopt it in place."
  default     = null
  type        = string
}

variable "load_balancer_sg_name" {
  description = "(optional) Name of the load balancer security group. Used as a prefix unless `use_sg_name_prefix` is false. If null, will use `$${local.load_balancer_name}-lb-sg-` (prefix) or `$${local.load_balancer_name}-lb-sg` (exact name)."
  default     = null
  type        = string
}

variable "load_balancer_sg_description" {
  description = "(optional) Description for the load balancer security group. Defaults to `Controls access to the <name> load balancer`. `description` is ForceNew on aws_security_group, so match an existing group's description to adopt it in place."
  default     = null
  type        = string
}

variable "use_sg_name_prefix" {
  description = "(optional) Treat `security_group_name` and `load_balancer_sg_name` as name prefixes, letting AWS append a unique suffix. Set to false to give the security groups those exact names. Exact-named groups cannot be replaced in place, since the replacement would collide with the name of the original"
  default     = true
  type        = bool
}

############################
# IAM and integrations
############################

variable "iam_role_name" {
  description = "(optional) Name of the instance IAM role and profile (defaults to the module name). Must be unique in the account"
  default     = null
  type        = string
}

variable "enable_ssm" {
  description = "(optional) Attach AmazonSSMManagedInstanceCore so the instance works with Session Manager and Patch Manager"
  default     = true
  type        = bool
}

variable "enable_cloudwatch_agent" {
  description = "(optional) Attach CloudWatchAgentServerPolicy to the instance role"
  default     = false
  type        = bool
}

variable "extra_policy_arns" {
  description = "(optional) Managed policy ARNs to attach to the instance role"
  default     = []
  type        = list(string)
}

variable "extra_role_policy_json" {
  description = "(optional) Extra IAM policy (JSON) merged into the module's inline policy on the instance role, without replacing the generated statements"
  default     = null
  type        = string
}

variable "s3_bucket_arns" {
  description = "(optional) S3 bucket ARNs the instance can read from and write to"
  default     = []
  type        = list(string)
  validation {
    condition     = alltrue([for a in var.s3_bucket_arns : can(regex("^arn:aws[a-z-]*:s3:::[^/]+$", a))])
    error_message = "Each s3_bucket_arns entry must be a bucket ARN (arn:aws:s3:::bucket-name) without an object path."
  }
}

variable "s3_read_only_bucket_arns" {
  description = "(optional) S3 bucket ARNs the instance can only read from"
  default     = []
  type        = list(string)
  validation {
    condition     = alltrue([for a in var.s3_read_only_bucket_arns : can(regex("^arn:aws[a-z-]*:s3:::[^/]+$", a))])
    error_message = "Each s3_read_only_bucket_arns entry must be a bucket ARN (arn:aws:s3:::bucket-name) without an object path."
  }
}

variable "secrets_manager_arns" {
  description = "(optional) Secrets Manager secret ARNs the instance can read (secrets referenced in the secrets variable are granted automatically)"
  default     = []
  type        = list(string)
}

variable "ssm_parameter_paths" {
  description = "(optional) SSM parameter names or paths the instance can read, e.g. /PROD/MYAPP. Each grants the parameter itself and everything beneath it"
  default     = []
  type        = list(string)
  validation {
    condition     = alltrue([for p in var.ssm_parameter_paths : startswith(p, "/")])
    error_message = "Each ssm_parameter_paths entry must start with /."
  }
}

variable "kms_key_arns" {
  description = "(optional) KMS key ARNs the instance can use to encrypt/decrypt (customer-managed keys for S3, SSM, secrets, etc.)"
  default     = []
  type        = list(string)
}

variable "sqs_queue_arns" {
  description = "(optional) SQS queue ARNs the instance can send to and receive from"
  default     = []
  type        = list(string)
}

variable "sns_topic_arns" {
  description = "(optional) SNS topic ARNs the instance can publish to"
  default     = []
  type        = list(string)
}

variable "dynamodb_table_arns" {
  description = "(optional) DynamoDB table ARNs the instance can read and write (including their indexes)"
  default     = []
  type        = list(string)
}

variable "data_store_connections" {
  description = "(optional) Data stores (RDS, ElastiCache, OpenSearch, EFS, ...) the instance connects to, keyed by a short name. The module adds an ingress rule on each security_group_id allowing the instance's security group on port, like an ECS service. Example: { db = { security_group_id = \"sg-...\", port = 5432 } }"
  default     = {}
  type = map(object({
    security_group_id = string
    port              = number
    protocol          = optional(string, "tcp")
    description       = optional(string)
  }))
  validation {
    condition     = alltrue([for c in values(var.data_store_connections) : can(regex("^sg-[0-9a-f]+$", c.security_group_id))])
    error_message = "Each data_store_connections security_group_id must look like sg-0123456789abcdef0."
  }
}

############################
# Application config
############################

variable "environment_variables" {
  description = "(optional) Plain environment variables written to /etc/pbs/app.env (root-only, mode 0600) at first boot. Values appear in user data and Terraform state: use secrets for anything sensitive. Single-line values only"
  default     = {}
  type        = map(string)
  validation {
    condition     = alltrue([for k in keys(var.environment_variables) : can(regex("^[A-Za-z_][A-Za-z0-9_]*$", k))])
    error_message = "Each environment_variables key must be a valid shell variable name."
  }
}

variable "secrets" {
  description = "(optional) Environment variable name => SSM parameter name (e.g. /PROD/MYAPP/DB_PASSWORD) or Secrets Manager secret ARN. Values are fetched at first boot with the instance role and written to /etc/pbs/app.env; they never enter Terraform state. Requires the AWS CLI on the AMI"
  default     = {}
  type        = map(string)
  validation {
    condition     = alltrue([for k in keys(var.secrets) : can(regex("^[A-Za-z_][A-Za-z0-9_]*$", k))])
    error_message = "Each secrets key must be a valid shell variable name."
  }
  validation {
    condition = alltrue([
      for v in values(var.secrets) :
      startswith(v, "arn:") ? can(regex("^arn:aws[a-z-]*:secretsmanager:", v)) : true
    ])
    error_message = "Each secrets value must be an SSM parameter name or a Secrets Manager secret ARN."
  }
}

variable "user_data" {
  description = "(optional) Shell script run at first boot. When environment_variables or secrets are set it runs after the module's env-file bootstrap, so it must be a shell script, not cloud-config"
  default     = null
  type        = string
  validation {
    condition = (
      var.user_data == null ||
      (length(var.environment_variables) == 0 && length(var.secrets) == 0) ||
      !startswith(coalesce(var.user_data, ""), "#cloud-config")
    )
    error_message = "user_data cannot be cloud-config when environment_variables or secrets are set; use a shell script."
  }
}

variable "user_data_replace_on_change" {
  description = "(optional) Replace the instance when user data changes. Off by default so env/secret edits never destroy a running server; user data only runs on first boot"
  default     = false
  type        = bool
}

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
