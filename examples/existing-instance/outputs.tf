output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "additional_volume_ids" {
  description = "Volumes attached to the instance"
  value       = module.ec2.additional_volume_ids
}

output "iam_role_name" {
  description = "Name of the instance IAM role"
  value       = module.ec2.iam_role_name
}
