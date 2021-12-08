variable "name" {
  description = "Name of Kinesis Firehose Stream"
  type        = string
}

variable "create_role" {
  description = "Specifies should role be created with module or will there be external one provided."
  type        = bool
  default     = true
}

variable "policy" {
  description = "List of additional policies for Firehose Stream access."
  type        = list(any)
  default     = []
}

variable "role" {
  description = "Custom role ARN used for Firehoste Stream."
  type        = string
  default     = ""
}

variable "destination_type" {
  description = "Type of destination for the Stream."
  type        = string
  default     = "extended_s3"
}

variable "enable_sse" {
  description = "Switch for enabling Server Side Encryption."
  type        = bool
  default     = true
}

variable "sse_kms_key" {
  description = "ARN of Customer Manager KMS key used for encryption."
  type        = string
  default     = ""
}

variable "enable_cloudwatch_logging" {
  description = "Switch for enabling log delivery to CloudWatch Log Group."
  type        = bool
  default     = false
}

variable "create_cloudwatch" {
  description = "Switch for creating default Cloudwatch Log Group and Log Stream."
  type        = bool
  default     = false
}

variable "cloudwatch_config" {
  description = "Map of all values for log delivery to CloudWatch Log Group."
  type        = any
  default     = {}
}

variable "extended_s3_config" {
  description = "Map of all values for extended s3 destination configuration."
  type        = any
  default     = {}
}

variable "enable_s3_backup" {
  description = "Switch for enabling S3 backup cappability."
  type        = bool
  default     = false
}

variable "s3_backup_configuration" {
  description = "Map of all values for S3 backup configuration, mostly same options as for extended_s3_config."
  type        = any
  default     = {}
}

variable "enable_processing" {
  description = "Switch for enabling processing via Lambda Function."
  type        = bool
  default     = false
}

variable "processing_lambda_arn" {
  description = "Qualified ARN of Lambda Function that will do data processing before writing results to destination."
  type        = string
  default     = ""
}
