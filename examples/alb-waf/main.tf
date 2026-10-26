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
  # Protection is on by default; the toggle lets tests and sandboxes destroy what they create
  disable_api_termination    = var.deletion_protection
  enable_deletion_protection = var.deletion_protection

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
