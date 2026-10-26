resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = local.subnet_id
  private_ip    = var.private_ip
  key_name      = var.key_name

  vpc_security_group_ids = concat([aws_security_group.this.id], var.extra_security_group_ids)
  iam_instance_profile   = aws_iam_instance_profile.this.name

  associate_public_ip_address          = var.associate_public_ip_address
  source_dest_check                    = var.source_dest_check
  ebs_optimized                        = var.ebs_optimized
  monitoring                           = var.monitoring
  disable_api_termination              = var.disable_api_termination
  disable_api_stop                     = var.disable_api_stop
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  user_data                   = local.user_data
  user_data_replace_on_change = var.user_data_replace_on_change

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.imds_http_tokens
    http_put_response_hop_limit = var.imds_hop_limit
  }

  root_block_device {
    volume_size           = var.root_volume.size
    volume_type           = var.root_volume.type
    iops                  = var.root_volume.iops
    throughput            = var.root_volume.throughput
    encrypted             = var.root_volume.encrypted
    kms_key_id            = var.root_volume.kms_key_id
    delete_on_termination = var.root_volume.delete_on_termination
    tags                  = merge(local.tags, { Name = "${local.name}-root" })
  }

  dynamic "credit_specification" {
    for_each = var.cpu_credits != null ? [var.cpu_credits] : []

    content {
      cpu_credits = credit_specification.value
    }
  }

  tags = local.tags
}

# The primary network interface is created by EC2 along with the instance, so neither the
# instance's tags nor the provider's default_tags reach it: tag it explicitly with both.
resource "aws_ec2_tag" "primary_network_interface" {
  for_each = merge(data.aws_default_tags.common_tags.tags, local.tags)

  resource_id = aws_instance.this.primary_network_interface_id
  key         = each.key
  value       = each.value
}

# Volumes are separate resources with their own attachment so data survives instance replacement.
resource "aws_ebs_volume" "this" {
  for_each = { for k, v in var.additional_ebs_volumes : k => v if v.volume_id == null }

  availability_zone = data.aws_subnet.selected.availability_zone
  size              = each.value.size
  type              = each.value.type
  iops              = each.value.iops
  throughput        = each.value.throughput
  encrypted         = each.value.encrypted
  kms_key_id        = each.value.kms_key_id
  snapshot_id       = each.value.snapshot_id
  final_snapshot    = each.value.final_snapshot

  tags = merge(local.tags, { Name = "${local.name}-${each.key}" })
}

resource "aws_volume_attachment" "this" {
  for_each = var.additional_ebs_volumes

  device_name = each.value.device_name
  volume_id   = each.value.volume_id != null ? each.value.volume_id : aws_ebs_volume.this[each.key].id
  instance_id = aws_instance.this.id

  stop_instance_before_detaching = true
}
