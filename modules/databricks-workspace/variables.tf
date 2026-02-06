# variable "aws_account_id" {
#   description = "AWS Account ID"
#   type        = string
# }

variable "databricks_account_id" {
  description = "Databricks Account ID"
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

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "tags" {
  description = "Description for resource tagging"
  type        = map(string)
}
