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
