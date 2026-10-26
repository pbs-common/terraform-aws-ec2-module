data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "Ec2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = coalesce(var.iam_role_name, local.name)
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = local.tags
}

resource "aws_iam_instance_profile" "this" {
  name = aws_iam_role.this.name
  role = aws_iam_role.this.name

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = var.enable_cloudwatch_agent ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# count rather than for_each: ARNs may come from resources that are not created yet
resource "aws_iam_role_policy_attachment" "additional" {
  count = length(var.extra_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.extra_policy_arns[count.index]
}

data "aws_iam_policy_document" "integrations" {
  source_policy_documents = var.extra_role_policy_json != null ? [var.extra_role_policy_json] : []

  dynamic "statement" {
    for_each = length(var.s3_bucket_arns) > 0 ? [1] : []

    content {
      sid       = "S3BucketReadWriteList"
      actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
      resources = var.s3_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_bucket_arns) > 0 ? [1] : []

    content {
      sid = "S3ObjectReadWrite"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts",
      ]
      resources = [for a in var.s3_bucket_arns : "${a}/*"]
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_read_only_bucket_arns) > 0 ? [1] : []

    content {
      sid       = "S3BucketReadOnlyList"
      actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
      resources = var.s3_read_only_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_read_only_bucket_arns) > 0 ? [1] : []

    content {
      sid       = "S3ObjectReadOnly"
      actions   = ["s3:GetObject", "s3:GetObjectVersion"]
      resources = [for a in var.s3_read_only_bucket_arns : "${a}/*"]
    }
  }

  dynamic "statement" {
    for_each = length(local.secrets_manager_arns) > 0 ? [1] : []

    content {
      sid       = "SecretsManagerRead"
      actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      resources = local.secrets_manager_arns
    }
  }

  dynamic "statement" {
    for_each = length(local.ssm_read_arns) > 0 ? [1] : []

    content {
      sid       = "SsmParameterRead"
      actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
      resources = local.ssm_read_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.kms_key_arns) > 0 ? [1] : []

    content {
      sid = "KmsUse"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:ReEncrypt*",
        "kms:DescribeKey",
      ]
      resources = var.kms_key_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.sqs_queue_arns) > 0 ? [1] : []

    content {
      sid = "SqsSendReceive"
      actions = [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:ChangeMessageVisibility",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
      ]
      resources = var.sqs_queue_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.sns_topic_arns) > 0 ? [1] : []

    content {
      sid       = "SnsPublish"
      actions   = ["sns:Publish"]
      resources = var.sns_topic_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.dynamodb_table_arns) > 0 ? [1] : []

    content {
      sid = "DynamoDbReadWrite"
      actions = [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
      ]
      resources = concat(var.dynamodb_table_arns, [for a in var.dynamodb_table_arns : "${a}/index/*"])
    }
  }
}

resource "aws_iam_role_policy" "integrations" {
  count = local.has_inline_policy ? 1 : 0

  name   = "${local.name}-integrations"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.integrations.json
}
