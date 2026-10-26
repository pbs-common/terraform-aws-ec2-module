# Only the required inputs: the VPC is looked up from the environment tag and the instance
# lands in a private subnet, exactly like the ECS service module's lookups.
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
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "AMI to launch"
  type        = string
}
