variable "PROJECT_NAME" {}

variable "ENV" {}

variable "RESOURCE_SUFFIX" {}

variable "AWS_TAGS" {
  type = map(string)
}

variable "LOG_STREAM_NAME" {}

variable "STREAM_DESTINATION" {}

variable "S3_BUCKET_ARN" {}

variable "TIME_FORMAT_PREFIX" {}

variable "ERROR_OUTPUT_PREFIX" {}

variable "BUFFER_SIZE" {}

variable "BUFFER_INTERVAL" {}

variable "ENABLE_DYNAMIC_PARTITIONING" {
  type = bool
}

variable "EXTRACTION_QUERY" {}

variable "COMPRESSION_FORMAT_TYPE" {
  description = "The compression format. Supported values are GZIP, ZIP, Snappy, & HADOOP_SNAPP"
  default     = "UNCOMPRESSED"
}

