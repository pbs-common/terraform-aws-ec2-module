output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "private_ip" {
  description = "Private IP of the instance"
  value       = module.ec2.private_ip
}

output "iam_role_name" {
  description = "Name of the instance IAM role"
  value       = module.ec2.iam_role_name
}
