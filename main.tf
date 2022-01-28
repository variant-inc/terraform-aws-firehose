data "aws_region" "current" {}

resource "aws_iam_role" "role" {
  count = var.create_role ? 1 : 0
  name  = format("AWSKinesisFirehoseRole-%s", var.name)
  tags  = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  dynamic "inline_policy" {
    for_each = var.destination_type == "extended_s3" ? [true] : []

    content {
      name = "s3_destination_access"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [{
          "Effect" : "Allow",
          "Action" : [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ],
          "Resource" : [
            lookup(var.extended_s3_config, "bucket_arn", ""),
            format("%s/*", lookup(var.extended_s3_config, "bucket_arn", ""))
          ]
        }]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = var.destination_type == "extended_s3" && var.enable_s3_backup ? [true] : []

    content {
      name = "s3_backup_access"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [{
          "Effect" : "Allow",
          "Action" : [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ],
          "Resource" : [
            lookup(var.s3_backup_configuration, "bucket_arn", ""),
            format("%s/*", lookup(var.s3_backup_configuration, "bucket_arn", ""))
          ]
        }]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = var.enable_sse && length(var.sse_kms_key) != 0 ? [true] : []

    content {
      name = "kms_key_access"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [{
          "Effect" : "Allow",
          "Action" : [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          "Resource" : [
            var.sse_kms_key
          ],
          "Condition" : {
            "StringEquals" : {
              "kms:ViaService" : format("s3.%s.amazonaws.com", data.aws_region.current.name)
            },
            "StringLike" : {
              "kms:EncryptionContext:aws:s3:arn" : format("%s/%s*", lookup(var.extended_s3_config, "bucket_arn", ""), lookup(var.extended_s3_config, "prefix", ""))
            }
          }
        }]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = var.enable_processing ? [true] : []

    content {
      name = "processing_lambda_access"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [{
          "Effect" : "Allow",
          "Action" : [
            "lambda:InvokeFunction",
            "lambda:GetFunctionConfiguration"
          ],
          "Resource" : [
            var.processing_lambda_arn
          ]
        }]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = var.enable_cloudwatch_logging ? [true] : []

    content {
      name = "cloudwatch_logs_access"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [{
          "Effect" : "Allow",
          "Action" : [
            "logs:PutLogEvents"
          ],
          "Resource" : compact([
            try(format("arn:aws:logs:region:account-id:log-group:%s:log-stream:%s", lookup(var.cloudwatch_config, "log_group_name", null), lookup(var.cloudwatch_config, "log_stream_name", null)), ""),
            try(aws_cloudwatch_log_stream.log_stream[0].arn, "")
          ])
        }]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = var.policy

    content {
      name   = lookup(inline_policy.value, "name", "")
      policy = jsonecode(lookup(inline_policy.value, "policy", {}))
    }
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  count = var.enable_cloudwatch_logging && var.create_cloudwatch ? 1 : 0

  name              = format("aws-firehose-logs-%s", var.name)
  tags              = var.tags
  retention_in_days = 0
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  count = var.enable_cloudwatch_logging && var.create_cloudwatch ? 1 : 0

  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.log_group[0].name
}

resource "aws_kinesis_firehose_delivery_stream" "stream" {
  name        = var.name
  tags        = var.tags
  destination = var.destination_type

  dynamic "server_side_encryption" {
    for_each = var.enable_sse ? [true] : []

    content {
      enabled  = true
      key_type = length(var.sse_kms_key) != 0 ? "CUSTOMER_MANAGED_CMK" : "AWS_OWNED_CMK"
      key_arn  = length(var.sse_kms_key) != 0 ? var.sse_kms_key : null
    }
  }

  dynamic "extended_s3_configuration" {
    for_each = var.destination_type == "extended_s3" ? [true] : []

    content {
      role_arn           = var.create_role ? aws_iam_role.role[0].arn : var.role
      bucket_arn         = lookup(var.extended_s3_config, "bucket_arn", null)
      prefix             = lookup(var.extended_s3_config, "prefix", null)
      buffer_size        = lookup(var.extended_s3_config, "buffer_size", null)
      buffer_interval    = lookup(var.extended_s3_config, "buffer_interval", null)
      compression_format = lookup(var.extended_s3_config, "compression_format", null)
      kms_key_arn        = lookup(var.extended_s3_config, "kms_key_arn", null)

      dynamic "cloudwatch_logging_options" {
        for_each = var.enable_cloudwatch_logging ? [true] : []

        content {
          enabled         = var.create_cloudwatch ? true : lookup(var.cloudwatch_config, "enabled", null)
          log_group_name  = var.create_cloudwatch ? aws_cloudwatch_log_group.log_group[0].name : lookup(var.cloudwatch_config, "log_group_name", null)
          log_stream_name = var.create_cloudwatch ? aws_cloudwatch_log_stream.log_stream[0].name : lookup(var.cloudwatch_config, "log_stream_name", null)
        }
      }
      error_output_prefix = lookup(var.extended_s3_config, "error_output_prefix", null)

      s3_backup_mode = var.enable_s3_backup ? "Enabled" : "Disabled"
      dynamic "s3_backup_configuration" {
        for_each = var.enable_s3_backup ? [var.s3_backup_configuration] : []

        content {
          role_arn           = var.create_role ? aws_iam_role.role[0].arn : var.role
          bucket_arn         = lookup(var.s3_backup_configuration, "bucket_arn", null)
          prefix             = lookup(var.s3_backup_configuration, "prefix", null)
          buffer_size        = lookup(var.s3_backup_configuration, "buffer_size", null)
          buffer_interval    = lookup(var.s3_backup_configuration, "buffer_interval", null)
          compression_format = lookup(var.s3_backup_configuration, "compression_format", null)
          kms_key_arn        = lookup(var.s3_backup_configuration, "kms_key_arn", null)

          dynamic "cloudwatch_logging_options" {
            for_each = var.enable_cloudwatch_logging ? [true] : []

            content {
              enabled         = var.create_cloudwatch ? true : lookup(var.cloudwatch_config, "enabled", null)
              log_group_name  = var.create_cloudwatch ? aws_cloudwatch_log_group.log_group[0].name : lookup(var.cloudwatch_config, "log_group_name", null)
              log_stream_name = var.create_cloudwatch ? aws_cloudwatch_log_stream.log_stream[0].name : lookup(var.cloudwatch_config, "log_stream_name", null)
            }
          }
        }
      }

      dynamic "processing_configuration" {
        for_each = var.enable_processing ? [true] : []

        content {
          enabled = var.enable_processing
          processors {
            type = "Lambda"
            parameters {
              parameter_name  = "LambdaArn"
              parameter_value = var.processing_lambda_arn
            }
          }
        }
      }
    }
  }
}