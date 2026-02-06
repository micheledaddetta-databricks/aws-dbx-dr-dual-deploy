output "workspace_id" {
  description = "Azure resource ID of the Databricks workspace"
  value       = databricks_mws_workspaces.this.id
}

output "workspace_url" {
  description = "URL of the Databricks workspace"
  value       = databricks_mws_workspaces.this.workspace_url
}

output "workspace_resource_id" {
  description = "Databricks workspace ID (for Unity Catalog assignment)"
  value       = databricks_mws_workspaces.this.workspace_id
}

# output "aws_account_id" {
#   description = "ID of the AWS Account"
#   value       = var.aws_account_id
# }

output "location" {
  description = "AWS region where resources are deployed"
  value       = var.location
}

output "random_suffix" {
  description = "Random suffix used for resource naming"
  value       = var.suffix
}