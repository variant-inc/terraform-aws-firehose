# Terraform AWS Kinesis Firehose module

- [Terraform AWS Kinesis Firehose module](#terraform-aws-kinesis-firehose-module)
  - [Input Variables](#input-variables)
  - [Variable definitions](#variable-definitions)
    - [name](#name)
    - [create_role](#create_role)
    - [policy](#policy)
    - [role](#role)
    - [destination_type](#destination_type)
    - [enable_sse](#enable_sse)
    - [sse_kms_key](#sse_kms_key)
    - [enable_cloudwatch_logging](#enable_cloudwatch_logging)
    - [create_cloudwatch](#create_cloudwatch)
    - [cloudwatch_config](#cloudwatch_config)
    - [extended_s3_config](#extended_s3_config)
    - [enable_s3_backup](#enable_s3_backup)
    - [s3_backup_configuration](#s3_backup_configuration)
    - [enable_processing](#enable_processing)
    - [processing_lambda_arn](#processing_lambda_arn)
  - [Examples](#examples)
    - [`main.tf`](#maintf)
    - [`terraform.tfvars.json`](#terraformtfvarsjson)
    - [`provider.tf`](#providertf)
    - [`variables.tf`](#variablestf)
    - [`outputs.tf`](#outputstf)

## Input Variables
| Name     | Type    | Default   | Example     | Notes   |
| -------- | ------- | --------- | ----------- | ------- |
| name | string |  | "test-firehose" |  |
| create_role | bool | true | false |  |
| policy | lis(any) | [] | `see below` |  |
| role | string | "" | "arn:aws:iam::319244236588:role/AWSKinesisFirehoseRole-test-firehose" |  |
| destination_type | string | "extended_s3" |  |  |
| enable_sse | bool | true | false |  |
| sse_kms_key | string | "" | "arn:aws:kms:us-east-1:319244236588:key/dfed962d-0968-42b4-ad36-7762dac7ca20" |  |
| enable_cloudwatch_logging | bool | false | true |  |
| create_cloudwatch | bool | false | true |  |
| cloudwatch_config | any | {} | `see below` |  |
| extended_s3_config | any | {} | `see below` |  |
| enable_s3_backup | bool | false | true |  |
| s3_backup_configuration | any | {} | `see below` |  |
| enable_processing | bool | false | true |  |
| processing_lambda_arn | string | "" | "arn:aws:lambda:us-east-1:319244236588:function:luka-lambda-test" |  |

## Variable definitions

### name
Name for Kinesis Firehose. Also used in naming connected resources.
```json
"name": "<name of Kinesis Firehose>"
```

### create_role
Specifies if IAM role for the Kinesis Firehose will be created in module or externally.
`true` - created with module
`false` - created externally
```json
"create_role": <true or false>
```

Default:
```json
"create_role": true
```

### policy
Additional inline policy statements for Kinesis Firehose role.
Effective only if `create_role` is set to `true`.
```json
"policy": [<list of inline policies>]
```

Default:
```json
"policy": []
```

### role
ARN of externally created role. Use in case of `create_role` is set to `false`.
```json
"role": "<role ARN>"
```

Default:
```json
"role": ""
```

### destination_type
Currently module has support only for `extended_s3` but can be upgraded and some components can be reused (s3 backup config, cloudwatch settings, role, processing block).
```json
"destination_type": "<extended_s3, redshift, elasticsearch, splunk or http_endpoint>"
```

Default:
```json
"destination_type": "extended_s3"
```

### enable_sse
Switch for enabling Server Side Encryption.
By default set to true and uses AWS Managed KMS key, custom one can be specified with `sse_kms_key`.
```json
"enable_sse": <true or false>
```

Default:
```json
"enable_sse": true
```

### sse_kms_key
ARN of Customer Manager KMS key used for encryption.
Valid only if `enable_sse` is `true`.
If ommited delivery streams data will be encrypted by AWS managed KMS key.
```json
"sse_kms_key": "<ARN of KMS key>"
```

Default:
```json
"sse_kms_key": ""
```

### enable_cloudwatch_logging
Switch for enabling log delivery to CloudWatch Log Group.
If set to `true` at least one of `create_cloudwatch` or `cloudwatch_config` have to be set.
```json
"enable_cloudwatch_logging": <true or false>
```

Default:
```json
"enable_cloudwatch_logging": false
```

### create_cloudwatch
Switch for creating default CloudWatch Log Group and Log Stream.
Defaults to `true`
```json
"create_cloudwatch": <true or false>
```

Default:
```json
"create_cloudwatch": false
```

### cloudwatch_config
Map of all values required for configuring delivery of logs to CloudWatch Logs.
```json
"cloudwatch_config": {
  "enabled": <true or false>,
  "log_group_name": "<CloudWatch Log Group name>",
  "log_stream_name": "<CloudWatch Log Group Stream name>"
}
```

Default:
```json
"cloudwatch_config": {}
```

### extended_s3_config
Map of all values for extended s3 destination configuration.
```json
"extended_s3_config": {
  "bucket_arn": "<ARN of destination s3 bucket>",
  "prefix": "<prefix in destination s3 bucket for delivery>",
  "buffer_size": <buffer size in MB>,
  "buffer_interval": <number of seconds before data is delivered>,
  "compression_format": "<UNCOMPRESSED, GZIP, ZIP, Snappy or HADOOP_SNAPPY>",
  "kms_key_arn": "<KMS key ARN for encryption on S3 bucket>"
}
```

Default:
```json
"extended_s3_config": {}
```

### enable_s3_backup
Switch for enabling S3 backup cappability.
```json
"enable_s3_backup": <true or false>
```

Default:
```json
"enable_s3_backup": false
```

### s3_backup_configuration
Map of all values for S3 backup configuration, mostly same options as for extended_s3_config.
```json
"s3_backup_configuration": {
  "bucket_arn": "<ARN of destination s3 bucket>",
  "prefix": "<prefix in destination s3 bucket for delivery>",
  "buffer_size": <buffer size in MB>,
  "buffer_interval": <number of seconds before data is delivered>,
  "compression_format": "<UNCOMPRESSED, GZIP, ZIP, Snappy or HADOOP_SNAPPY>",
  "kms_key_arn": "<KMS key ARN for encryption on S3 bucket>"
}
```

Default:
```json
"s3_backup_configuration": {}
```

### enable_processing
Switch for enabling processing via Lambda Function.
```json
"enable_processing": <true or false>
```

Default:
```json
"enable_processing": false
```

### processing_lambda_arn
Qualified ARN of Lambda Function that will do data processing before writing results to destination.
```json
"processing_lambda_arn": "<Qualified ARN of Lambda Function>"
```

Default:
```json
"processing_lambda_arn": ""
```

## Examples
### `main.tf`
```terarform
module "firehose" {
  source = "github.com/variant-inc/terrafor-aws-firehose/?refs=v1"

  name        = var.name
  create_role = var.create_role
  policy      = var.policy
  role        = var.role

  destination_type = var.destination_type
  enable_sse       = var.enable_sse
  sse_kms_key      = var.sse_kms_key
  
  enable_cloudwatch_logging = var.enable_cloudwatch_logging
  create_cloudwatch         = var.create_cloudwatch
  cloudwatch_config         = var.cloudwatch_config
  enable_s3_backup          = var.enable_s3_backup
  s3_backup_configuration   = var.s3_backup_configuration
  enable_processing         = var.enable_processing
  processing_lambda_arn     = var.processing_lambda_arn
  extended_s3_config        = var.extended_s3_config
}
```

### `terraform.tfvars.json`
```json
{
  "name": "test-firehose",
  "destination_type": "extended_s3",
  "extended_s3_config": {
    "bucket_arn": "arn:aws:s3:::test-luka-290183",
    "prefix": "firehose_data/",
    "buffer_size": 5,
    "buffer_interval": 10,
    "compression_format": "UNCOMPRESSED",
    "kms_key_arn": "arn:aws:kms:us-east-1:319244236588:key/dfed962d-0968-42b4-ad36-7762dac7ca20"
  },
  "create_role": true,
  "policy": [
    {
      "name": "additional_policy",
      "policy": {
        "Version": "2012-10-17",
        "Statement": [{
          "Sid": "s3full",
          "Effect": "Allow",
          "Action": "s3:*",
          "Resourcee": "*"
        }]
      }
    }
  ],
  "enable_processing": true,
  "processing_lambda_arn": "arn:aws:lambda:us-east-1:319244236588:function:luka-lambda-test",
  "enable_sse": true,
  "sse_kms_key": "arn:aws:kms:us-east-1:319244236588:key/dfed962d-0968-42b4-ad36-7762dac7ca20",
  "enable_cloudwatch_logging": true,
  "create_cloudwatch": false,
  "cloudwatch_config": {
    "enabled": true,
    "log_group_name": "test_cw_log_group",
    "log_stream_name": "S3Delivery"
  },
  "enable_s3_backup": true,
  "s3_backup_configuration": {
    "bucket_arn": "arn:aws:s3:::test-luka-backup-290183",
    "prefix": "firehose_backup/",
    "buffer_size": 5,
    "buffer_interval": 10,
    "compression_format": "ZIP",
    "kms_key_arn": "arn:aws:kms:us-east-1:319244236588:key/dfed962d-0968-42b4-ad36-7762dac7ca20"
  }
}
```

Basic
```json
{
  "name": "test-firehose",
  "extended_s3_config": {
    "bucket_arn": "arn:aws:s3:::test-luka-290183"
  }
}
```

### `provider.tf`
```terraform
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      team : "DataOps",
      purpose : "firehose_test",
      owner : "Luka"
    }
  }
}
```

### `variables.tf`
copy ones from module

### `outputs.tf`
```terraform
output "firehose_arn" {
  value       = module.firehose.arn
  description = "ARN of Kinesis Firehose"
}
```