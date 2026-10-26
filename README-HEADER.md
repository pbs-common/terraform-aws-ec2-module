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
