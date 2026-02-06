# =====================================================================
# Common Variables
# =====================================================================

variable "prefix" {
  description = "Prefix for primary workspace resource naming (e.g., username, environment)"
  type        = string
}

variable "location" {
  description = "Azure region for primary workspace deployment"
  type        = string
}

variable "email" {
  description = "Owner email for resource tagging"
  type        = string
}

variable "remove_date" {
  description = "Date when resources should be removed (for tagging)"
  type        = string
}

variable "description" {
  description = "Description for resource tagging"
  type        = string
  default     = "Databricks Private Link with Unity Catalog and NCC"
}

# =====================================================================
# Secondary Workspace Variables
# =====================================================================

variable "deploy_secondary_workspace" {
  description = "Whether to deploy a secondary workspace in a different region (will use same config as primary with 'replica' suffix)"
  type        = bool
  default     = false
}

variable "location_secondary" {
  description = "Azure region for secondary workspace deployment"
  type        = string
  default     = ""
}

# =====================================================================
# AWS Account Variables
# =====================================================================

variable "aws_primary_account_id" {
  description = "AWS primary account ID"
  type        = string
}

variable "aws_secondary_account_id" {
  description = "AWS primary account ID"
  type        = string
  default     = ""
}

# =====================================================================
# Databricks Account Variables
# =====================================================================

variable "databricks_account_id" {
  description = "Databricks account console ID for account-level operations"
  type        = string
}

# =====================================================================
# Networking Variables
# =====================================================================

variable "cidr" {
  description = "CIDR block for the virtual network"
  type        = string
}


# =====================================================================
# Unity Catalog Variables
# =====================================================================

variable "uc_metastore_name" {
  description = "Name for the Unity Catalog metastore (secondary will auto-append '-replica')"
  type        = string
}

variable "create_external_location" {
  description = "Whether to create an external storage location (applies to both primary and secondary)"
  type        = bool
  default     = true
}

variable "external_location_name" {
  description = "Name for the external location in Unity Catalog (secondary will auto-append '_replica')"
  type        = string
  default     = "external_data"
}

# =====================================================================
# NCC Variables
# =====================================================================

variable "enable_ncc" {
  description = "Whether to enable Network Connectivity Config for storage (applies to both primary and secondary)"
  type        = bool
  default     = true
}

# =====================================================================
# M2M OAuth Variables
# =====================================================================

variable "databricks_client_id" {
  description = "Databricks Service Principal OAuth Client ID"
}

variable "databricks_client_secret" {
  description = "Databricks Service Principal OAuth Client Secret"
}