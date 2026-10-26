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

variable "deletion_protection" {
  description = "Termination (and load balancer deletion) protection. Tests set this to false so they can destroy what they create"
  type        = bool
  default     = true
}
