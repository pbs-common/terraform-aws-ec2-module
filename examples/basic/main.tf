# Only the required inputs (plus the protection toggle): the VPC is looked up from the environment tag and the instance
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

  # Optional Parameters
  # Protection is on by default; the toggle lets tests and sandboxes destroy what they create
  disable_api_termination = var.deletion_protection
}
