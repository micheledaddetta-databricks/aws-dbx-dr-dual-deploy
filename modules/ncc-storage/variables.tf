variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "suffix" {
  description = "Random suffix for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region for the NCC"
  type        = string
}

variable "workspace_id" {
  description = "Databricks workspace ID to bind NCC to"
  type        = string
}

variable "s3_buckets" {
  description = "Map of S3 buckets to create private endpoint rules for"
  #   type = set(string)
  type = map(object({
    arn     = string
    id      = string
    account = string
  }))
}
