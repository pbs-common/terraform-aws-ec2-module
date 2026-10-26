variable "instance_type" {
  description = "EC2 instance type. Deliberately has no default: size it for the workload"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "The instance_type variable must look like m5.large."
  }
}

variable "ami_id" {
  description = "AMI to launch. Deliberately has no default: a floating latest AMI would replace the instance on the next apply after every AMI release"
  type        = string
  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "The ami_id variable must look like ami-0123456789abcdef0."
  }
}
