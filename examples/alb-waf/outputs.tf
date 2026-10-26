output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "lb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.ec2.lb_dns_name
}

output "web_acl_arn" {
  description = "ARN of the web ACL attached to the load balancer"
  value       = module.ec2.web_acl_arn
}
