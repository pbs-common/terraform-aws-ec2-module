# Recreates an instance that was built by hand: a pinned AMI, a key pair, security groups
# created outside Terraform, an unencrypted gp2 root volume and a separate data volume that
# must survive the instance. Nothing here is an account-specific value; see
# docs/module/existing-instances.md for how to read the real ones off an instance.
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
  name      = "${var.product}-${var.environment}-web"
  subnet_id = var.subnet_id # the VPC is derived from the subnet
  key_name  = var.key_name

  extra_security_group_ids = var.existing_security_group_ids

  root_volume = {
    size      = 20
    type      = "gp2"
    encrypted = false
  }

  additional_ebs_volumes = {
    data = {
      device_name = "/dev/sdf"
      volume_id   = var.data_volume_id # attach the existing volume instead of creating a new one
    }
  }

  # The old instance role is replaced by a module-created one; add back what it granted
  extra_policy_arns = var.extra_policy_arns
  s3_bucket_arns    = var.s3_bucket_arns

  # Reachable from an existing load balancer that this module does not manage
  security_group_ingress_rules = {
    http_from_lb = {
      from_port                    = 80
      to_port                      = 80
      referenced_security_group_id = var.existing_lb_security_group_id
    }
  }

  data_store_connections = {
    mysql = { security_group_id = var.rds_security_group_id, port = 3306 }
  }
}

variable "instance_type" {
  description = "Instance type of the existing instance"
  type        = string
}

variable "ami_id" {
  description = "AMI of the existing instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet of the existing instance (keeps the data volume in the same availability zone)"
  type        = string
}

variable "key_name" {
  description = "Key pair of the existing instance, if it has one"
  type        = string
  default     = null
}

variable "existing_security_group_ids" {
  description = "Security groups attached to the existing instance"
  type        = list(string)
  default     = []
}

variable "existing_lb_security_group_id" {
  description = "Security group of the existing load balancer that fronts the instance"
  type        = string
}

variable "data_volume_id" {
  description = "ID of the existing data volume to re-attach"
  type        = string
}

variable "extra_policy_arns" {
  description = "Managed policies the old instance role had"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "Buckets the old instance role could read and write"
  type        = list(string)
  default     = []
}

variable "rds_security_group_id" {
  description = "Security group of the database the app connects to"
  type        = string
}
