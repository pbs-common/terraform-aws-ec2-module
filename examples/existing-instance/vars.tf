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
