# PBS TF EC2 Module

## Installation

### Using the Repo Source

```hcl
github.com/pbs/terraform-aws-ec2-module?ref=x.y.z
```

### Alternative Installation Methods

More information can be found on these install methods and more in [the documentation here](./docs/general/install).

## Usage

Deploys a single EC2 instance following PBS standards: IMDSv2 required, encrypted gp3 root volume, SSM Session Manager access, termination protection on, a module-created IAM role and security group, and standard billing tags on every resource.

`instance_type` and `ami_id` are required and deliberately have no default: sizing is workload-specific, and a floating "latest" AMI would replace the instance on the next apply after every AMI release.

Like the [ECS service module](https://github.com/pbs-common/terraform-aws-ecs-service-module), the network is discovered when not given: `vpc_id` (or the VPC of `subnet_id`, or the VPC whose `Name` tag contains the `environment`), then a `*-private-*` subnet (optionally in `availability_zone`). See [existing instances](./docs/module/existing-instances.md) for the lookup rules and their limits.

Optional pieces, all off by default:

- **Load balancer** (`create_lb`): ALB, target group and HTTP/HTTPS listeners, with the same conventions as the ECS module: `lb_scheme`, `hosted_zone` (Route 53 alias records and wildcard ACM certificate lookup), `acm_arn`, HTTP-to-HTTPS redirect, and a default 403 with host-header / custom-header forwarding rules. Deletion protection is on.
- **WAF** (`create_waf` or `web_acl_arn`): create a regional web ACL with AWS managed rule groups and an optional rate limit, or attach an existing one.
- **Integrations**, modelled on the ECS service module: IAM inputs for S3, Secrets Manager, SSM, KMS, SQS, SNS and DynamoDB; `data_store_connections` to open RDS/ElastiCache/etc. security groups to the instance; `environment_variables` and `secrets` written to `/etc/pbs/app.env` at first boot.
- **Extra EBS volumes** (`additional_ebs_volumes`): created, restored from a snapshot, or an existing volume re-attached, always as separate attachments so data outlives the instance.

Termination protection and load balancer deletion protection are on by default; set `disable_api_termination` and `enable_deletion_protection` to `false` and apply before destroying.

See [existing instances](./docs/module/existing-instances.md) for recreating hand-built instances with this module.

Integrate this module like so:

```hcl
module "ec2" {
  source = "github.com/pbs/terraform-aws-ec2-module?ref=x.y.z"

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
}
```

## Adding This Version of the Module

If this repo is added as a subtree, then the version of the module should be close to the version shown here:

`x.y.z`

Note, however that subtrees can be altered as desired within repositories.

Further documentation on usage can be found [here](./docs).

Below is automatically generated documentation on this Terraform module using [terraform-docs][terraform-docs]

---

[terraform-docs]: https://github.com/terraform-docs/terraform-docs

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.70.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ebs_volume.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ec2_tag.primary_network_interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.integrations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_listener_rule.http_application_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.https_application_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_route53_record.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_volume_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_vpc_security_group_egress_rule.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.lb_to_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.data_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.lb_to_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.user_to_lb_http_cidrs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.user_to_lb_http_prefix_lists](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.user_to_lb_http_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.user_to_lb_https_cidrs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.user_to_lb_https_prefix_lists](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.user_to_lb_https_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_wafv2_web_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_logging_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |
| [aws_acm_certificate.primary_acm_wildcard_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.common_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.integrations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.hosted_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnet.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.supplied](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.lb_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.lb_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI to launch. Deliberately has no default: a floating latest AMI would replace the instance on the next apply after every AMI release | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (sharedtools, dev, staging, qa, prod) | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type. Deliberately has no default: size it for the workload | `string` | n/a | yes |
| <a name="input_organization"></a> [organization](#input\_organization) | Organization using this module. Used to prefix tags so that they are easily identified as being from your organization | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Tag used to group resources according to product | `string` | n/a | yes |
| <a name="input_product"></a> [product](#input\_product) | Tag used to group resources according to product | `string` | n/a | yes |
| <a name="input_repo"></a> [repo](#input\_repo) | Tag used to point to the repo using this module | `string` | n/a | yes |
| <a name="input_acm_arn"></a> [acm\_arn](#input\_acm\_arn) | (optional) ARN of the ACM certificate for the HTTPS listener. If null and hosted\_zone is set on a public load balancer, the wildcard certificate of the hosted zone is looked up. If still null, only an HTTP listener is created | `string` | `null` | no |
| <a name="input_additional_ebs_volumes"></a> [additional\_ebs\_volumes](#input\_additional\_ebs\_volumes) | (optional) Extra EBS volumes keyed by a short name (used in the Name tag). Set volume\_id to attach an existing volume instead of creating one, snapshot\_id to restore from a snapshot. Volumes are always attached with a separate attachment so they survive instance replacement | <pre>map(object({<br/>    device_name    = string<br/>    size           = optional(number)<br/>    type           = optional(string, "gp3")<br/>    iops           = optional(number)<br/>    throughput     = optional(number)<br/>    encrypted      = optional(bool, true)<br/>    kms_key_id     = optional(string)<br/>    snapshot_id    = optional(string)<br/>    volume_id      = optional(string)<br/>    final_snapshot = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_alb_ssl_policy"></a> [alb\_ssl\_policy](#input\_alb\_ssl\_policy) | (optional) SSL policy to use for the HTTPS listener. | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | (optional) CNAME(s) that are allowed to be used for this instance, matched as host headers by the listener rules. Default is `name`.`hosted_zone` when hosted\_zone is set. e.g. [name.example.com] | `list(string)` | `null` | no |
| <a name="input_allow_all_egress"></a> [allow\_all\_egress](#input\_allow\_all\_egress) | (optional) Allow all outbound traffic from the module-created instance security group | `bool` | `true` | no |
| <a name="input_app_port"></a> [app\_port](#input\_app\_port) | (optional) Port the application listens on inside the instance. The load balancer forwards to it and the instance security group allows the load balancer on it | `number` | `80` | no |
| <a name="input_app_protocol"></a> [app\_protocol](#input\_app\_protocol) | (optional) Protocol the load balancer uses to talk to the application: HTTP or HTTPS | `string` | `"HTTP"` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | (optional) Associate a public IPv4 address with the instance | `bool` | `false` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | (optional) Availability zone to place the instance in when subnet\_id is null, e.g. us-east-1a. Ignored when subnet\_id is set. If null, the first matching subnet by ID is used | `string` | `null` | no |
| <a name="input_cnames"></a> [cnames](#input\_cnames) | (optional) CNAME(s) that are going to be created for the load balancer in the hosted\_zone. This can be set to [] to avoid creating a CNAME, which can be useful for CDNs. Default is `name` when hosted\_zone is set. e.g. [name] --> [name.example.com] | `list(string)` | `null` | no |
| <a name="input_cpu_credits"></a> [cpu\_credits](#input\_cpu\_credits) | (optional) CPU credit mode for burstable (t2/t3/t3a/t4g) instances: standard or unlimited. Null keeps the AWS default | `string` | `null` | no |
| <a name="input_create_lb"></a> [create\_lb](#input\_create\_lb) | (optional) Create an Application Load Balancer and target group in front of the instance | `bool` | `false` | no |
| <a name="input_create_waf"></a> [create\_waf](#input\_create\_waf) | (optional) Create a regional WAFv2 web ACL and attach it to the load balancer. Requires create\_lb | `bool` | `false` | no |
| <a name="input_custom_http_headers"></a> [custom\_http\_headers](#input\_custom\_http\_headers) | (optional) Custom HTTP headers a request must carry to be forwarded. Format should be a list of maps with `name` and `value` keys. e.g. [{ name = "header1", value = "value1"}] | `list(object({ name = string, value = string }))` | `[]` | no |
| <a name="input_data_store_connections"></a> [data\_store\_connections](#input\_data\_store\_connections) | (optional) Data stores (RDS, ElastiCache, OpenSearch, EFS, ...) the instance connects to, keyed by a short name. The module adds an ingress rule on each security\_group\_id allowing the instance's security group on port, like an ECS service. Example: { db = { security\_group\_id = "sg-...", port = 5432 } } | <pre>map(object({<br/>    security_group_id = string<br/>    port              = number<br/>    protocol          = optional(string, "tcp")<br/>    description       = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_disable_api_stop"></a> [disable\_api\_stop](#input\_disable\_api\_stop) | (optional) Enable EC2 stop protection | `bool` | `false` | no |
| <a name="input_disable_api_termination"></a> [disable\_api\_termination](#input\_disable\_api\_termination) | (optional) EC2 termination protection. On by default: set to false before destroying the instance | `bool` | `true` | no |
| <a name="input_dns_evaluate_target_health"></a> [dns\_evaluate\_target\_health](#input\_dns\_evaluate\_target\_health) | (optional) Evaluate health of endpoints by querying DNS records | `bool` | `false` | no |
| <a name="input_dynamodb_table_arns"></a> [dynamodb\_table\_arns](#input\_dynamodb\_table\_arns) | (optional) DynamoDB table ARNs the instance can read and write (including their indexes) | `list(string)` | `[]` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | (optional) Launch as EBS-optimized. Null uses the instance type default | `bool` | `null` | no |
| <a name="input_enable_cloudwatch_agent"></a> [enable\_cloudwatch\_agent](#input\_enable\_cloudwatch\_agent) | (optional) Attach CloudWatchAgentServerPolicy to the instance role | `bool` | `false` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | (optional) Protect the load balancer from deletion. On by default: set to false before destroying the load balancer | `bool` | `true` | no |
| <a name="input_enable_ssm"></a> [enable\_ssm](#input\_enable\_ssm) | (optional) Attach AmazonSSMManagedInstanceCore so the instance works with Session Manager and Patch Manager | `bool` | `true` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | (optional) Plain environment variables written to /etc/pbs/app.env (root-only, mode 0600) at first boot. Values appear in user data and Terraform state: use secrets for anything sensitive. Single-line values only | `map(string)` | `{}` | no |
| <a name="input_extra_acm_arns"></a> [extra\_acm\_arns](#input\_extra\_acm\_arns) | (optional) List of additional ACM certificate ARNs to attach to the HTTPS listener. | `list(string)` | `[]` | no |
| <a name="input_extra_lb_security_group_ids"></a> [extra\_lb\_security\_group\_ids](#input\_extra\_lb\_security\_group\_ids) | (optional) List of additional security group IDs to attach to the load balancer, alongside the module-managed load balancer security group. Ignored when no load balancer is created. | `list(string)` | `[]` | no |
| <a name="input_extra_policy_arns"></a> [extra\_policy\_arns](#input\_extra\_policy\_arns) | (optional) Managed policy ARNs to attach to the instance role | `list(string)` | `[]` | no |
| <a name="input_extra_role_policy_json"></a> [extra\_role\_policy\_json](#input\_extra\_role\_policy\_json) | (optional) Extra IAM policy (JSON) merged into the module's inline policy on the instance role, without replacing the generated statements | `string` | `null` | no |
| <a name="input_extra_security_group_ids"></a> [extra\_security\_group\_ids](#input\_extra\_security\_group\_ids) | (optional) List of additional security group IDs to attach to the instance, alongside the module-managed security group | `list(string)` | `[]` | no |
| <a name="input_healthcheck_healthy_threshold"></a> [healthcheck\_healthy\_threshold](#input\_healthcheck\_healthy\_threshold) | (optional) The number of consecutive health check successes required before considering an unhealthy target healthy | `number` | `3` | no |
| <a name="input_healthcheck_interval"></a> [healthcheck\_interval](#input\_healthcheck\_interval) | (optional) The approximate amount of time, in seconds, between health checks of the target | `number` | `10` | no |
| <a name="input_healthcheck_matcher"></a> [healthcheck\_matcher](#input\_healthcheck\_matcher) | (optional) The HTTP codes to use when checking for a successful response from a target | `string` | `"200"` | no |
| <a name="input_healthcheck_path"></a> [healthcheck\_path](#input\_healthcheck\_path) | (optional) The destination for the health check request. Null uses the AWS default (/) | `string` | `null` | no |
| <a name="input_healthcheck_port"></a> [healthcheck\_port](#input\_healthcheck\_port) | (optional) The port used for health checks: a port number or traffic-port | `string` | `"traffic-port"` | no |
| <a name="input_healthcheck_protocol"></a> [healthcheck\_protocol](#input\_healthcheck\_protocol) | (optional) The protocol to use to connect with the target. Null uses app\_protocol | `string` | `null` | no |
| <a name="input_healthcheck_timeout"></a> [healthcheck\_timeout](#input\_healthcheck\_timeout) | (optional) The amount of time, in seconds, during which no response means a failed health check | `number` | `6` | no |
| <a name="input_healthcheck_unhealthy_threshold"></a> [healthcheck\_unhealthy\_threshold](#input\_healthcheck\_unhealthy\_threshold) | (optional) The number of consecutive health check failures required before considering the target unhealthy | `number` | `3` | no |
| <a name="input_hosted_zone"></a> [hosted\_zone](#input\_hosted\_zone) | (optional) Name of the hosted zone for DNS. e.g. hosted\_zone = example.org --> service.example.org. Based on is\_hosted\_zone\_private, this is the primary or the private hosted zone. If null, no DNS records are created | `string` | `null` | no |
| <a name="input_http_port"></a> [http\_port](#input\_http\_port) | (optional) HTTP port number. | `number` | `80` | no |
| <a name="input_http_redirect"></a> [http\_redirect](#input\_http\_redirect) | (optional) Redirect HTTP traffic to HTTPS. If set to false, the HTTP listener behaves like the HTTPS one. Only applies when there is an HTTPS listener | `bool` | `true` | no |
| <a name="input_https_port"></a> [https\_port](#input\_https\_port) | (optional) HTTPS port number. | `number` | `443` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | (optional) Name of the instance IAM role and profile (defaults to the module name). Must be unique in the account | `string` | `null` | no |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | (optional) Idle timeout for the load balancer. If null, will use whatever the default is for the load balancer. | `number` | `null` | no |
| <a name="input_imds_hop_limit"></a> [imds\_hop\_limit](#input\_imds\_hop\_limit) | (optional) IMDS PUT response hop limit. Raise to 2 if containers on the instance need the metadata service | `number` | `1` | no |
| <a name="input_imds_http_tokens"></a> [imds\_http\_tokens](#input\_imds\_http\_tokens) | (optional) Instance metadata service version: required enforces IMDSv2 (PBS standard) | `string` | `"required"` | no |
| <a name="input_instance_initiated_shutdown_behavior"></a> [instance\_initiated\_shutdown\_behavior](#input\_instance\_initiated\_shutdown\_behavior) | (optional) What happens when the OS shuts down: stop or terminate | `string` | `"stop"` | no |
| <a name="input_instance_subnet_scheme"></a> [instance\_subnet\_scheme](#input\_instance\_subnet\_scheme) | (optional) Subnet placement when subnet\_id is null. "private" (default) uses *-private-* subnets, "public" uses *-public-* subnets | `string` | `"private"` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | (optional) Use an internal load balancer. If null, will be internal when lb\_scheme is internal. | `bool` | `null` | no |
| <a name="input_is_hosted_zone_private"></a> [is\_hosted\_zone\_private](#input\_is\_hosted\_zone\_private) | (optional) Is the route53 zone private or not. | `bool` | `false` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | (optional) Name of an existing EC2 key pair. Leave null and use SSM Session Manager where possible | `string` | `null` | no |
| <a name="input_kms_key_arns"></a> [kms\_key\_arns](#input\_kms\_key\_arns) | (optional) KMS key ARNs the instance can use to encrypt/decrypt (customer-managed keys for S3, SSM, secrets, etc.) | `list(string)` | `[]` | no |
| <a name="input_lb_access_logs_bucket"></a> [lb\_access\_logs\_bucket](#input\_lb\_access\_logs\_bucket) | (optional) S3 bucket name for load balancer access logs. Null disables access logs | `string` | `null` | no |
| <a name="input_lb_access_logs_prefix"></a> [lb\_access\_logs\_prefix](#input\_lb\_access\_logs\_prefix) | (optional) Key prefix for load balancer access logs | `string` | `null` | no |
| <a name="input_lb_deregistration_delay"></a> [lb\_deregistration\_delay](#input\_lb\_deregistration\_delay) | (optional) Seconds the target group waits before deregistering the instance | `number` | `30` | no |
| <a name="input_lb_ingress_cidr_blocks"></a> [lb\_ingress\_cidr\_blocks](#input\_lb\_ingress\_cidr\_blocks) | (optional) CIDR blocks allowed to reach the load balancer (HTTP/HTTPS ingress). Defaults to open internet access. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_lb_ingress_prefix_list_ids"></a> [lb\_ingress\_prefix\_list\_ids](#input\_lb\_ingress\_prefix\_list\_ids) | (optional) Prefix lists allowed to reach the load balancer (HTTP/HTTPS ingress) | `list(string)` | `[]` | no |
| <a name="input_lb_scheme"></a> [lb\_scheme](#input\_lb\_scheme) | (optional) Scheme for the load balancer and its subnet selection. "public" creates an internet-facing LB in public subnets. "internal" creates an internal LB in private subnets. | `string` | `"public"` | no |
| <a name="input_listener_default_action"></a> [listener\_default\_action](#input\_listener\_default\_action) | (optional) What the listeners do with requests that match no rule: `fixed_response` or `forward`. When null: `fixed_response` if there are host header aliases or custom\_http\_headers to match on, otherwise `forward` | `string` | `null` | no |
| <a name="input_listener_default_message_body"></a> [listener\_default\_message\_body](#input\_listener\_default\_message\_body) | (optional) Body returned with the listeners' default fixed response. Null sends an empty body. | `string` | `null` | no |
| <a name="input_listener_default_status_code"></a> [listener\_default\_status\_code](#input\_listener\_default\_status\_code) | (optional) HTTP status code returned by the default fixed-response action of the listeners. Requests that match no listener rule get this. | `string` | `"403"` | no |
| <a name="input_listener_rule_host_header"></a> [listener\_rule\_host\_header](#input\_listener\_rule\_host\_header) | (optional) Match the aliases with a `host_header` condition on the listener rules. Set to false to route on `custom_http_headers` alone, for an instance reachable only through a CDN that injects a shared secret header, say. With this false a single rule is created per listener instead of one per alias | `bool` | `true` | no |
| <a name="input_load_balancer_name"></a> [load\_balancer\_name](#input\_load\_balancer\_name) | (optional) Load balancer name, max 32 characters. Will default to the module name truncated to 32 if not defined. | `string` | `null` | no |
| <a name="input_load_balancer_sg_description"></a> [load\_balancer\_sg\_description](#input\_load\_balancer\_sg\_description) | (optional) Description for the load balancer security group. Defaults to `Controls access to the <name> load balancer`. `description` is ForceNew on aws\_security\_group, so match an existing group's description to adopt it in place. | `string` | `null` | no |
| <a name="input_load_balancer_sg_name"></a> [load\_balancer\_sg\_name](#input\_load\_balancer\_sg\_name) | (optional) Name of the load balancer security group. Used as a prefix unless `use_sg_name_prefix` is false. If null, will use `${local.load_balancer_name}-lb-sg-` (prefix) or `${local.load_balancer_name}-lb-sg` (exact name). | `string` | `null` | no |
| <a name="input_monitoring"></a> [monitoring](#input\_monitoring) | (optional) Enable detailed (1 minute) CloudWatch monitoring | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | (optional) Name of the instance and prefix for related resources (defaults to product if null) | `string` | `null` | no |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | (optional) Fixed private IPv4 address inside the subnet. Null lets AWS choose | `string` | `null` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | (optional) Private subnets for an internal load balancer (at least two availability zones). If null, they are looked up in the VPC by name (*-private-*). Not used for the instance: see subnet\_id | `list(string)` | `null` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | (optional) Public subnets for an internet-facing load balancer (at least two availability zones). If null, they are looked up in the VPC by name (*-public-*). Not used for the instance: see subnet\_id | `list(string)` | `null` | no |
| <a name="input_restricted_sg"></a> [restricted\_sg](#input\_restricted\_sg) | (optional) SG allowed to reach the load balancer, in addition to lb\_ingress\_cidr\_blocks. If null, no sg will be configured to connect | `string` | `null` | no |
| <a name="input_root_volume"></a> [root\_volume](#input\_root\_volume) | (optional) Root EBS volume settings. Encrypted by default (PBS standard); set encrypted = false only to mirror an existing unencrypted volume | <pre>object({<br/>    size                  = optional(number, 30)<br/>    type                  = optional(string, "gp3")<br/>    iops                  = optional(number)<br/>    throughput            = optional(number)<br/>    encrypted             = optional(bool, true)<br/>    kms_key_id            = optional(string)<br/>    delete_on_termination = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_route_priority"></a> [route\_priority](#input\_route\_priority) | (optional) Starting route priority, incremented by each listener rule | `number` | `10` | no |
| <a name="input_s3_bucket_arns"></a> [s3\_bucket\_arns](#input\_s3\_bucket\_arns) | (optional) S3 bucket ARNs the instance can read from and write to | `list(string)` | `[]` | no |
| <a name="input_s3_read_only_bucket_arns"></a> [s3\_read\_only\_bucket\_arns](#input\_s3\_read\_only\_bucket\_arns) | (optional) S3 bucket ARNs the instance can only read from | `list(string)` | `[]` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | (optional) Environment variable name => SSM parameter name (e.g. /PROD/MYAPP/DB\_PASSWORD) or Secrets Manager secret ARN. Values are fetched at first boot with the instance role and written to /etc/pbs/app.env; they never enter Terraform state. Requires the AWS CLI on the AMI | `map(string)` | `{}` | no |
| <a name="input_secrets_manager_arns"></a> [secrets\_manager\_arns](#input\_secrets\_manager\_arns) | (optional) Secrets Manager secret ARNs the instance can read (secrets referenced in the secrets variable are granted automatically) | `list(string)` | `[]` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | (optional) Description for the instance security group. Defaults to `Controls access to the <name> instance`. `description` is ForceNew on aws\_security\_group, so match an existing group's description to adopt it in place. | `string` | `null` | no |
| <a name="input_security_group_ingress_rules"></a> [security\_group\_ingress\_rules](#input\_security\_group\_ingress\_rules) | (optional) Extra ingress rules on the module-created instance security group, keyed by a unique name. Exactly one source per rule: cidr\_ipv4, cidr\_ipv6, prefix\_list\_id or referenced\_security\_group\_id. Use protocol = "-1" for all traffic (ports are then ignored) | <pre>map(object({<br/>    description                  = optional(string)<br/>    protocol                     = optional(string, "tcp")<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | (optional) Name of the instance security group. Used as a prefix unless `use_sg_name_prefix` is false. If null, will use `${local.name}-sg-` (prefix) or `${local.name}-sg` (exact name). | `string` | `null` | no |
| <a name="input_sns_topic_arns"></a> [sns\_topic\_arns](#input\_sns\_topic\_arns) | (optional) SNS topic ARNs the instance can publish to | `list(string)` | `[]` | no |
| <a name="input_source_dest_check"></a> [source\_dest\_check](#input\_source\_dest\_check) | (optional) Enable the source/destination check (disable only for NAT/proxy instances) | `bool` | `true` | no |
| <a name="input_sqs_queue_arns"></a> [sqs\_queue\_arns](#input\_sqs\_queue\_arns) | (optional) SQS queue ARNs the instance can send to and receive from | `list(string)` | `[]` | no |
| <a name="input_ssm_parameter_paths"></a> [ssm\_parameter\_paths](#input\_ssm\_parameter\_paths) | (optional) SSM parameter names or paths the instance can read, e.g. /PROD/MYAPP. Each grants the parameter itself and everything beneath it | `list(string)` | `[]` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | (optional) Subnet the instance is launched in. If null, one is looked up in the VPC by name (*-private-* or *-public-*, see instance\_subnet\_scheme), optionally restricted to availability\_zone | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags | `map(string)` | `{}` | no |
| <a name="input_target_group_name"></a> [target\_group\_name](#input\_target\_group\_name) | (optional) Target group name, max 32 characters. Will default to the module name truncated to 32 if not defined. | `string` | `null` | no |
| <a name="input_use_sg_name_prefix"></a> [use\_sg\_name\_prefix](#input\_use\_sg\_name\_prefix) | (optional) Treat `security_group_name` and `load_balancer_sg_name` as name prefixes, letting AWS append a unique suffix. Set to false to give the security groups those exact names. Exact-named groups cannot be replaced in place, since the replacement would collide with the name of the original | `bool` | `true` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | (optional) Shell script run at first boot. When environment\_variables or secrets are set it runs after the module's env-file bootstrap, so it must be a shell script, not cloud-config | `string` | `null` | no |
| <a name="input_user_data_replace_on_change"></a> [user\_data\_replace\_on\_change](#input\_user\_data\_replace\_on\_change) | (optional) Replace the instance when user data changes. Off by default so env/secret edits never destroy a running server; user data only runs on first boot | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | (optional) VPC ID. If null, the VPC of subnet\_id is used; if that is null too, one will be looked up based on environment tag. | `string` | `null` | no |
| <a name="input_waf_default_action"></a> [waf\_default\_action](#input\_waf\_default\_action) | (optional) Default action of the created web ACL: allow or block | `string` | `"allow"` | no |
| <a name="input_waf_log_destination_arn"></a> [waf\_log\_destination\_arn](#input\_waf\_log\_destination\_arn) | (optional) ARN of a CloudWatch log group, S3 bucket or Firehose stream (name starting aws-waf-logs-) for web ACL logs. Null disables logging | `string` | `null` | no |
| <a name="input_waf_managed_rule_groups"></a> [waf\_managed\_rule\_groups](#input\_waf\_managed\_rule\_groups) | (optional) Managed rule groups in the created web ACL, evaluated in list order. rules\_to\_count switches individual rules to count-only | <pre>list(object({<br/>    name           = string<br/>    vendor_name    = optional(string, "AWS")<br/>    rules_to_count = optional(list(string), [])<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "AWSManagedRulesCommonRuleSet"<br/>  },<br/>  {<br/>    "name": "AWSManagedRulesKnownBadInputsRuleSet"<br/>  },<br/>  {<br/>    "name": "AWSManagedRulesAmazonIpReputationList"<br/>  }<br/>]</pre> | no |
| <a name="input_waf_rate_limit"></a> [waf\_rate\_limit](#input\_waf\_rate\_limit) | (optional) Block IPs exceeding this many requests per 5 minutes in the created web ACL. Null disables the rate rule | `number` | `null` | no |
| <a name="input_web_acl_arn"></a> [web\_acl\_arn](#input\_web\_acl\_arn) | (optional) ARN of an existing regional web ACL to attach to the load balancer instead of creating one. Requires create\_lb and cannot be combined with create\_waf | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_additional_volume_ids"></a> [additional\_volume\_ids](#output\_additional\_volume\_ids) | Map of additional\_ebs\_volumes key to EBS volume ID (created or supplied) |
| <a name="output_ami_id"></a> [ami\_id](#output\_ami\_id) | AMI the instance was launched from |
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Availability zone of the instance |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | FQDN of the first Route 53 record for the load balancer, or the load balancer DNS name when no record is created. Null without a load balancer |
| <a name="output_http_listener_arn"></a> [http\_listener\_arn](#output\_http\_listener\_arn) | ARN of the HTTP listener, if created |
| <a name="output_https_listener_arn"></a> [https\_listener\_arn](#output\_https\_listener\_arn) | ARN of the HTTPS listener, if created |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the instance IAM role |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the instance IAM role |
| <a name="output_instance_arn"></a> [instance\_arn](#output\_instance\_arn) | ARN of the EC2 instance |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | ID of the EC2 instance |
| <a name="output_instance_profile_name"></a> [instance\_profile\_name](#output\_instance\_profile\_name) | Name of the instance profile |
| <a name="output_lb_arn"></a> [lb\_arn](#output\_lb\_arn) | ARN of the load balancer, if created |
| <a name="output_lb_dns_name"></a> [lb\_dns\_name](#output\_lb\_dns\_name) | DNS name of the load balancer, if created |
| <a name="output_lb_security_group_id"></a> [lb\_security\_group\_id](#output\_lb\_security\_group\_id) | ID of the load balancer security group, if created |
| <a name="output_lb_zone_id"></a> [lb\_zone\_id](#output\_lb\_zone\_id) | Route 53 hosted zone ID of the load balancer, if created (for alias records) |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | Private IPv4 address of the instance |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | Public IPv4 address of the instance, if any |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group created for the instance |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | ID of the subnet the instance is in (supplied or looked up) |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | ARN of the instance target group, if the load balancer was created |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC the instance is in (supplied, derived from the subnet, or looked up) |
| <a name="output_web_acl_arn"></a> [web\_acl\_arn](#output\_web\_acl\_arn) | ARN of the web ACL associated with the load balancer (created or supplied), if any |
