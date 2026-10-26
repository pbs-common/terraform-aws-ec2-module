module "ec2" {
  source = "../.."

  # Required Parameters
  instance_type = var.instance_type
  ami_id        = var.ami_id

  # Tagging Parameters
  organization = var.organization
  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo

  # Optional Parameters
  availability_zone = var.availability_zone

  # Public load balancer: subnets are looked up by name, the wildcard certificate of the hosted
  # zone is looked up, and <product>.<hosted_zone> is created and matched as the host header.
  # Anything that does not match the host header gets the default 403.
  create_lb        = true
  hosted_zone      = var.hosted_zone
  app_port         = 8080
  healthcheck_path = "/status"

  # Module-created web ACL with the default AWS managed rule groups and a rate limit
  create_waf     = true
  waf_rate_limit = 2000

  # Connect to data stores and AWS services
  data_store_connections = {
    postgres = { security_group_id = var.rds_security_group_id, port = 5432 }
    redis    = { security_group_id = var.cache_security_group_id, port = 6379 }
  }
  s3_bucket_arns           = [var.bucket_arn]
  s3_read_only_bucket_arns = [var.assets_bucket_arn]

  # Config written to /etc/pbs/app.env at first boot
  environment_variables = {
    APP_ENV = var.environment
  }
  secrets = {
    DATABASE_PASSWORD = "/${upper(var.environment)}/${upper(var.product)}/DATABASE_PASSWORD"
  }
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.large"
}

variable "ami_id" {
  description = "AMI to launch"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the instance"
  type        = string
  default     = "us-east-1a"
}

variable "hosted_zone" {
  description = "Public hosted zone, e.g. example.org"
  type        = string
}

variable "rds_security_group_id" {
  description = "Security group of the RDS instance the app connects to"
  type        = string
}

variable "cache_security_group_id" {
  description = "Security group of the ElastiCache cluster the app connects to"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of a bucket the app reads and writes"
  type        = string
}

variable "assets_bucket_arn" {
  description = "ARN of a bucket the app only reads"
  type        = string
}
