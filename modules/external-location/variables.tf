variable "databricks_account_id" {
  description = "Databricks Account ID"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "suffix" {
  description = "Random suffix for resource naming"
  type        = string
}

variable "location" {
  description = "AWS region for deployment"
  type        = string
}

variable "external_location_name" {
  description = "Name for the external location in Unity Catalog"
  type        = string
}

variable "workspace_id" {
  description = "Azure resource ID of the Databricks workspace"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
