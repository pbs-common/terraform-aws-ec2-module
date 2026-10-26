# Recreating existing instances

The module can reproduce an instance that was built by hand. See `examples/existing-instance` for a worked example. The module has no built-in knowledge of any account or application: everything below is read off the instance you are replacing.

## Reading an instance

Read these off the instance (`aws ec2 describe-instances`, `describe-volumes`) and map them to inputs:

| Instance attribute | Module input |
|---|---|
| Subnet (the VPC follows from it) | `subnet_id`, or `vpc_id` + `availability_zone` if the subnets follow the naming convention |
| AMI | `ami_id` |
| Instance type | `instance_type` |
| Key pair | `key_name` |
| Fixed private IP | `private_ip` |
| Security groups | `extra_security_group_ids` (the module also creates its own) |
| Root volume size / type / encryption | `root_volume` (`encrypted = false` to match an unencrypted original) |
| Extra volumes | `additional_ebs_volumes`, using `volume_id` to re-attach an existing volume, `snapshot_id` to restore |
| Termination protection | `disable_api_termination` (on by default) |
| Instance profile | see below |

## VPC and subnet discovery

Like the ECS service module, the module can find its own network:

1. `vpc_id` if set;
2. otherwise the VPC of `subnet_id` if set;
3. otherwise the one VPC whose `Name` tag contains the `environment` (`*<environment>*`). Zero or several matches is an error.

With no `subnet_id`, the instance goes into the first (by ID) `*-private-*` subnet of that VPC, or the one in `availability_zone` when set. `instance_subnet_scheme = "public"` uses `*-public-*` subnets instead. Load balancer subnets are looked up the same way and need two availability zones.

The tag lookup only works where VPCs and subnets follow the naming convention and the environment identifies exactly one VPC. Accounts where several environments share a VPC, and older VPCs whose subnets are not named by convention, need an explicit `subnet_id` (and `vpc_id` if the subnet is shared).

## IAM differs from the original

The module always creates its own role and instance profile; it cannot adopt an existing one. A recreated instance therefore gets a new role, and its permissions must be restated:

- managed policies the old role had: `extra_policy_arns`
- inline policies: `extra_role_policy_json`, or the typed inputs (`s3_bucket_arns`, `secrets_manager_arns`, ...)
- set `iam_role_name` if something else, such as a bucket policy, trusts the old role name. The old role must be deleted or renamed first, since names are unique per account.

## Adopting security groups and load balancers

Names and descriptions can be pinned so that existing resources are matched rather than replaced: `security_group_name`, `security_group_description`, `load_balancer_sg_name`, `load_balancer_sg_description`, `load_balancer_name`, `target_group_name`, with `use_sg_name_prefix = false` for exact security group names. `description` is ForceNew on a security group, so it must match exactly.

## Replacing safely

1. Re-attach data volumes with `volume_id` rather than letting the module create new ones. An existing volume cannot be attached to a new instance until it is detached from the old one, so stop the old instance first.
2. Termination protection and load balancer deletion protection are on by default. Set `disable_api_termination` / `enable_deletion_protection` to `false` and apply before destroying either.
3. `user_data` only runs on first boot. An AMI that already contains its configuration needs no user data.
4. Plan first and read the plan: AMI, subnet, key pair and `user_data` changes force replacement.
5. Bringing the old instance under Terraform state instead of replacing it is a separate, reviewed operation and is not covered by this module.

## Not covered

- Instances launched by Auto Scaling groups or OpsWorks stacks.
- Multiple network interfaces, placement groups, hibernation and Elastic IPs are not modelled. Create those alongside the module with the instance outputs.
- DNS records pointing straight at the instance. Records are only created for the load balancer, through `hosted_zone`.
- Redirect-only listener rules (the ECS module's `extra_http_listener_rules`) are not included; add them with `https_listener_arn` and `aws_lb_listener_rule`.
