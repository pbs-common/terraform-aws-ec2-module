output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IPv4 address of the instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IPv4 address of the instance, if any"
  value       = aws_instance.this.public_ip
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.this.availability_zone
}

output "ami_id" {
  description = "AMI the instance was launched from"
  value       = aws_instance.this.ami
}

output "vpc_id" {
  description = "ID of the VPC the instance is in (supplied, derived from the subnet, or looked up)"
  value       = local.vpc_id
}

output "subnet_id" {
  description = "ID of the subnet the instance is in (supplied or looked up)"
  value       = local.subnet_id
}

output "security_group_id" {
  description = "ID of the security group created for the instance"
  value       = aws_security_group.this.id
}

output "iam_role_arn" {
  description = "ARN of the instance IAM role"
  value       = aws_iam_role.this.arn
}

output "iam_role_name" {
  description = "Name of the instance IAM role"
  value       = aws_iam_role.this.name
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = aws_iam_instance_profile.this.name
}

output "additional_volume_ids" {
  description = "Map of additional_ebs_volumes key to EBS volume ID (created or supplied)"
  value       = { for k, v in aws_volume_attachment.this : k => v.volume_id }
}

output "lb_arn" {
  description = "ARN of the load balancer, if created"
  value       = one(aws_lb.this[*].arn)
}

output "lb_dns_name" {
  description = "DNS name of the load balancer, if created"
  value       = one(aws_lb.this[*].dns_name)
}

output "lb_zone_id" {
  description = "Route 53 hosted zone ID of the load balancer, if created (for alias records)"
  value       = one(aws_lb.this[*].zone_id)
}

output "lb_security_group_id" {
  description = "ID of the load balancer security group, if created"
  value       = one(aws_security_group.lb[*].id)
}

output "target_group_arn" {
  description = "ARN of the instance target group, if the load balancer was created"
  value       = one(aws_lb_target_group.this[*].arn)
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener, if created"
  value       = one(aws_lb_listener.http[*].arn)
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener, if created"
  value       = one(aws_lb_listener.https[*].arn)
}

output "domain_name" {
  description = "FQDN of the first Route 53 record for the load balancer, or the load balancer DNS name when no record is created. Null without a load balancer"
  value       = local.domain_name
}

output "web_acl_arn" {
  description = "ARN of the web ACL associated with the load balancer (created or supplied), if any"
  value       = local.attach_web_acl ? coalesce(var.web_acl_arn, one(aws_wafv2_web_acl.this[*].arn)) : null
}
