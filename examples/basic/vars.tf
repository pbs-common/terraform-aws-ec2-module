variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "AMI to launch"
  type        = string
}

variable "deletion_protection" {
  description = "Termination (and load balancer deletion) protection. Tests set this to false so they can destroy what they create"
  type        = bool
  default     = true
}
