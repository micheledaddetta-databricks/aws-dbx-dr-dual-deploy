# =====================================================================
# Databricks Workspace Outputs
# =====================================================================

output "workspace_id" {
  description = "ID of the Databricks workspace"
  value       = module.databricks_workspace.workspace_id
}

output "workspace_url" {
  description = "URL of the Databricks workspace"
  value       = module.databricks_workspace.workspace_url
}

output "workspace_resource_id" {
  description = "Databricks workspace ID (for Unity Catalog)"
  value       = module.databricks_workspace.workspace_resource_id
}

output "workspace_region" {
  description = "Workspace region"
  value       = module.databricks_workspace.location
}

# =====================================================================
# Unity Catalog Outputs
# =====================================================================

output "metastore_id" {
  description = "ID of the Unity Catalog metastore"
  value       = module.unity_catalog.metastore_id
}

output "metastore_name" {
  description = "Name of the Unity Catalog metastore"
  value       = module.unity_catalog.metastore_name
}

# =====================================================================
# External Location Outputs
# =====================================================================

output "external_s3_bucket_name" {
  description = "Name of the external S3 bucket"
  value       = var.create_external_location ? module.external_location[0].bucket_id : null
}

output "external_s3_bucket_arn" {
  description = "ARN of the external S3 bucket"
  value       = var.create_external_location ? module.external_location[0].bucket_arn : null
}

output "external_s3_bucket_url" {
  description = "URL of the Unity Catalog external location"
  value       = var.create_external_location ? module.external_location[0].external_location_url : null
}

# =====================================================================
# NCC Outputs
# =====================================================================

output "ncc_id" {
  description = "ID of the Network Connectivity Config"
  value       = var.enable_ncc ? module.ncc_storage[0].ncc_id : null
}

output "ncc_name" {
  description = "Name of the Network Connectivity Config"
  value       = var.enable_ncc ? module.ncc_storage[0].ncc_name : null
}

output "ncc_private_endpoint_rule" {
  description = "NCC private endpoint rule ID"
  value       = var.enable_ncc ? module.ncc_storage[0].private_endpoint_rule_id : null
}

# =====================================================================
# Secondary Workspace Outputs
# =====================================================================

output "workspace_id_secondary" {
  description = "Azure resource ID of the secondary Databricks workspace"
  value       = var.deploy_secondary_workspace ? module.databricks_workspace_secondary[0].workspace_id : null
}

output "workspace_url_secondary" {
  description = "URL of the secondary Databricks workspace"
  value       = var.deploy_secondary_workspace ? module.databricks_workspace_secondary[0].workspace_url : null
}

output "workspace_resource_id_secondary" {
  description = "Databricks workspace ID for secondary workspace (for Unity Catalog)"
  value       = var.deploy_secondary_workspace ? module.databricks_workspace_secondary[0].workspace_resource_id : null
}

output "workspace_region_secondary" {
  description = "Secondary workspace region"
  value       = var.deploy_secondary_workspace ? module.databricks_workspace_secondary[0].location : null
}

# =====================================================================
# Secondary Unity Catalog Outputs
# =====================================================================

output "metastore_id_secondary" {
  description = "ID of the secondary Unity Catalog metastore"
  value       = var.deploy_secondary_workspace ? module.unity_catalog_secondary[0].metastore_id : null
}

output "metastore_name_secondary" {
  description = "Name of the secondary Unity Catalog metastore"
  value       = var.deploy_secondary_workspace ? module.unity_catalog_secondary[0].metastore_name : null
}

# =====================================================================
# Secondary External Location Outputs
# =====================================================================

output "external_s3_bucket_name_secondary" {
  description = "Name of the secondary external storage account"
  value       = var.deploy_secondary_workspace && var.create_external_location ? module.external_location_secondary[0].bucket_id : null
}

output "external_s3_bucket_arn_secondary" {
  description = "Name of the secondary Unity Catalog external location"
  value       = var.deploy_secondary_workspace && var.create_external_location ? module.external_location_secondary[0].bucket_arn : null
}

output "external_s3_bucket_url_secondary" {
  description = "URL of the secondary Unity Catalog external location"
  value       = var.deploy_secondary_workspace && var.create_external_location ? module.external_location_secondary[0].external_location_url : null
}

# =====================================================================
# Secondary NCC Outputs
# =====================================================================

output "ncc_id_secondary" {
  description = "ID of the secondary Network Connectivity Config"
  value       = var.deploy_secondary_workspace && var.enable_ncc ? module.ncc_storage_secondary[0].ncc_id : null
}

output "ncc_name_secondary" {
  description = "Name of the secondary Network Connectivity Config"
  value       = var.deploy_secondary_workspace && var.enable_ncc ? module.ncc_storage_secondary[0].ncc_name : null
}

output "ncc_private_endpoint_rule_secondary" {
  description = "Secondary NCC private endpoint rules created"
  value       = var.deploy_secondary_workspace && var.enable_ncc ? module.ncc_storage_secondary[0].private_endpoint_rule_id : null
}

# =====================================================================
# Deployment Information
# =====================================================================

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    primary = {
      workspace_url             = module.databricks_workspace.workspace_url
      metastore_enabled         = true
      external_location_enabled = var.create_external_location
      ncc_enabled               = var.enable_ncc
      region                    = module.databricks_workspace.location
      aws_account               = var.aws_primary_account_id
    }
    secondary = var.deploy_secondary_workspace ? {
      workspace_url             = module.databricks_workspace_secondary[0].workspace_url
      metastore_enabled         = true
      external_location_enabled = var.create_external_location
      ncc_enabled               = var.enable_ncc
      region                    = module.databricks_workspace_secondary[0].location
      aws_account               = var.aws_secondary_account_id
    } : null
  }
}
