# =====================================================================
# Random String for Consistent Naming
# =====================================================================

resource "random_string" "global_suffix" {
  length  = 4
  lower   = true
  upper   = false
  special = false
}

# =====================================================================
# Locals Setup
# =====================================================================

locals {
  tags = {
    Environment = "Terraform-Managed"
    Owner       = var.email
    RemoveAfter = var.remove_date
    Descrption  = var.description
  }

  tags_secondary = merge(local.tags,
    {
      Description = "${var.description} - Secondary Region"
  })
}

# =====================================================================
# Azure Databricks Workspace with Private Link
# =====================================================================

module "databricks_workspace" {
  source = "./modules/databricks-workspace"

  prefix   = var.prefix
  suffix   = random_string.global_suffix.result
  location = var.location
  cidr     = var.cidr
  tags     = local.tags

  databricks_account_id = var.databricks_account_id

  providers = {
    databricks = databricks.account,
    aws        = aws.primary
  }
}

# =====================================================================
# Unity Catalog with Metastore
# =====================================================================

module "unity_catalog" {
  source = "./modules/unity-catalog"

  databricks_account_id = var.databricks_account_id
  aws_account_id        = var.aws_primary_account_id

  prefix         = var.prefix
  suffix         = random_string.global_suffix.result
  location       = module.databricks_workspace.location
  workspace_id   = module.databricks_workspace.workspace_resource_id
  metastore_name = var.uc_metastore_name

  tags = local.tags

  depends_on = [module.databricks_workspace]

  providers = {
    databricks.account   = databricks.account
    databricks.workspace = databricks.primary-workspace
    #     aws        = aws.primary
  }
}

# =====================================================================
# External Location for Unity Catalog
# =====================================================================

module "external_location" {
  count  = var.create_external_location ? 1 : 0
  source = "./modules/external-location"

  prefix                 = var.prefix
  suffix                 = random_string.global_suffix.result
  location               = module.databricks_workspace.location
  workspace_id           = module.databricks_workspace.workspace_id
  external_location_name = var.external_location_name

  tags = local.tags

  depends_on = [module.unity_catalog]

  providers = {
    databricks = databricks.primary-workspace
    aws        = aws.primary
  }

  databricks_account_id = var.databricks_account_id
  aws_account_id        = var.aws_primary_account_id
}

# =====================================================================
# Network Connectivity Config (NCC) for Storage
# =====================================================================

locals {

  # Build map of storage accounts for NCC
  s3_buckets = var.enable_ncc && var.create_external_location ? {
    primary = {
      arn     = module.external_location[0].bucket_arn
      id      = module.external_location[0].bucket_id
      account = "primary"
    }
  } : {}

  # Combined storage accounts for both NCCs (includes both primary and secondary)
  s3_buckets_combined = var.deploy_secondary_workspace && var.enable_ncc ? merge(local.s3_buckets, local.s3_buckets_secondary) : local.s3_buckets
}

module "ncc_storage" {
  count  = var.enable_ncc && var.create_external_location ? 1 : 0
  source = "./modules/ncc-storage"

  prefix       = var.prefix
  suffix       = random_string.global_suffix.result
  location     = module.databricks_workspace.location
  workspace_id = module.databricks_workspace.workspace_resource_id
  s3_buckets   = local.s3_buckets_combined

  depends_on = [
    module.unity_catalog,
    module.external_location,
    module.databricks_workspace
  ]

  providers = {
    databricks    = databricks.account
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
  }
}

data "aws_iam_policy_document" "allow_access_from_serverless" {
  for_each = local.s3_buckets

  provider = aws.primary

  statement {
    sid = "AllowDatabricksServerless"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      each.value.arn,
      "${each.value.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:VpceOrgPaths"
      values   = ["o-g29axo4oyt/r-gu8r/ou-gu8r-g4va1rkr/ou-gu8r-hvyilq7g/*"]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_serverless" {
  for_each = local.s3_buckets

  provider = aws.primary

  bucket = each.value.id
  policy = data.aws_iam_policy_document.allow_access_from_serverless[each.key].json
}

resource "time_sleep" "wait_connection_state" {

  create_duration = "120s"

  depends_on = [
    module.ncc_storage[0],
    aws_s3_bucket_policy.allow_access_from_serverless
  ]
}

resource "restapi_object" "enable_private_endpoint_rule" {
  count = var.deploy_secondary_workspace && var.enable_ncc && var.create_external_location ? 1 : 0

  object_id = module.ncc_storage[0].private_endpoint_rule_id
  path      = ""

  create_path  = "/api/2.0/accounts/${var.databricks_account_id}/network-connectivity-configs/${module.ncc_storage[0].ncc_id}/private-endpoint-rules/${module.ncc_storage[0].private_endpoint_rule_id}?update_mask=enabled"
  read_path    = "/api/2.0/accounts/${var.databricks_account_id}/network-connectivity-configs/${module.ncc_storage[0].ncc_id}/private-endpoint-rules/${module.ncc_storage[0].private_endpoint_rule_id}"
  update_path  = "/api/2.0/accounts/${var.databricks_account_id}/network-connectivity-configs/${module.ncc_storage[0].ncc_id}/private-endpoint-rules/${module.ncc_storage[0].private_endpoint_rule_id}?update_mask=enabled"
  destroy_path = "/api/2.0/accounts/${var.databricks_account_id}/network-connectivity-configs/${module.ncc_storage[0].ncc_id}/private-endpoint-rules/${module.ncc_storage[0].private_endpoint_rule_id}?update_mask=enabled"

  data         = "{\"endpoint_service\": \"${module.ncc_storage[0].private_endpoint_service}\",\"enabled\": true}"
  destroy_data = "{\"endpoint_service\": \"${module.ncc_storage[0].private_endpoint_service}\",\"enabled\": false}"

  depends_on = [time_sleep.wait_connection_state]
}


# =====================================================================
# SECONDARY WORKSPACE - Different Region
# =====================================================================

# Secondary Databricks Workspace with Private Link
# =====================================================================

module "databricks_workspace_secondary" {
  count  = var.deploy_secondary_workspace ? 1 : 0
  source = "./modules/databricks-workspace"

  prefix   = "${var.prefix}replica"
  suffix   = random_string.global_suffix.result
  location = var.location_secondary
  cidr     = var.cidr
  tags     = local.tags_secondary

  databricks_account_id = var.databricks_account_id

  providers = {
    databricks = databricks.account,
    aws        = aws.secondary
  }
}

# =====================================================================
# Secondary Unity Catalog with Metastore
# =====================================================================

module "unity_catalog_secondary" {
  count  = var.deploy_secondary_workspace ? 1 : 0
  source = "./modules/unity-catalog"

  databricks_account_id = var.databricks_account_id
  aws_account_id        = var.aws_secondary_account_id

  prefix         = "${var.prefix}replica"
  suffix         = random_string.global_suffix.result
  location       = module.databricks_workspace_secondary[0].location
  workspace_id   = module.databricks_workspace_secondary[0].workspace_resource_id
  metastore_name = "${var.uc_metastore_name}-replica"

  tags = local.tags_secondary

  depends_on = [module.databricks_workspace_secondary]

  providers = {
    databricks.account   = databricks.account
    databricks.workspace = databricks.secondary-workspace
  }
}

# =====================================================================
# Secondary External Location for Unity Catalog
# =====================================================================

module "external_location_secondary" {
  count  = var.deploy_secondary_workspace && var.create_external_location ? 1 : 0
  source = "./modules/external-location"

  prefix                 = "${var.prefix}replica"
  suffix                 = random_string.global_suffix.result
  location               = module.databricks_workspace_secondary[0].location
  workspace_id           = module.databricks_workspace_secondary[0].workspace_id
  external_location_name = "${var.external_location_name}_replica"

  tags = local.tags_secondary

  depends_on = [module.unity_catalog_secondary]

  providers = {
    databricks = databricks.secondary-workspace
    aws        = aws.secondary
  }

  databricks_account_id = var.databricks_account_id
  aws_account_id        = var.aws_primary_account_id
}

# =====================================================================
# Secondary Network Connectivity Config (NCC) for Storage
# =====================================================================

locals {
  # Build map of storage accounts for secondary NCC
  s3_buckets_secondary = var.deploy_secondary_workspace && var.enable_ncc && var.create_external_location ? {
    secondary = {
      arn     = module.external_location_secondary[0].bucket_arn
      id      = module.external_location_secondary[0].bucket_id
      account = "secondary"
    }
  } : {}
}


module "ncc_storage_secondary" {
  count  = var.deploy_secondary_workspace && var.enable_ncc && var.create_external_location ? 1 : 0
  source = "./modules/ncc-storage"

  prefix       = "${var.prefix}replica"
  suffix       = random_string.global_suffix.result
  location     = module.databricks_workspace_secondary[0].location
  workspace_id = module.databricks_workspace_secondary[0].workspace_resource_id
  s3_buckets   = local.s3_buckets_combined

  depends_on = [
    module.unity_catalog_secondary,
    module.external_location_secondary,
    module.databricks_workspace_secondary
  ]

  providers = {
    databricks    = databricks.account
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
  }
}

data "aws_iam_policy_document" "allow_access_from_serverless_secondary" {
  for_each = local.s3_buckets_secondary

  provider = aws.secondary

  statement {
    sid = "AllowDatabricksServerless"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      each.value.arn,
      "${each.value.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:VpceOrgPaths"
      values   = ["o-g29axo4oyt/r-gu8r/ou-gu8r-g4va1rkr/ou-gu8r-hvyilq7g/*"]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_serverless_secondary" {
  for_each = local.s3_buckets_secondary

  provider = aws.secondary

  bucket = each.value.id
  policy = data.aws_iam_policy_document.allow_access_from_serverless_secondary[each.key].json
}

resource "time_sleep" "wait_connection_state_secondary" {

  create_duration = "120s"

  depends_on = [
    module.ncc_storage_secondary[0],
    aws_s3_bucket_policy.allow_access_from_serverless_secondary
  ]
}

resource "restapi_object" "enable_private_endpoint_rule_secondary" {
  count = var.deploy_secondary_workspace && var.enable_ncc && var.create_external_location ? 1 : 0

  object_id = module.ncc_storage_secondary[0].private_endpoint_rule_id
  path      = ""

  create_path  = "/api/2.0/accounts/${var.databricks_account_id}/network-connectivity-configs/${module.ncc_storage_secondary[0].ncc_id}/private-endpoint-rules/${module.ncc_storage_secondary[0].private_endpoint_rule_id}?update_mask=enabled"
  read_path    = "/api/2.0/accounts/${var.databricks_account_id}/network-connectivity-configs/${module.ncc_storage_secondary[0].ncc_id}/private-endpoint-rules/${module.ncc_storage_secondary[0].private_endpoint_rule_id}"
  update_path  = "/api/2.0/accounts/${var.databricks_account_id}/network-connectivity-configs/${module.ncc_storage_secondary[0].ncc_id}/private-endpoint-rules/${module.ncc_storage_secondary[0].private_endpoint_rule_id}?update_mask=enabled"
  destroy_path = "/api/2.0/accounts/${var.databricks_account_id}/network-connectivity-configs/${module.ncc_storage_secondary[0].ncc_id}/private-endpoint-rules/${module.ncc_storage_secondary[0].private_endpoint_rule_id}?update_mask=enabled"

  data         = "{\"endpoint_service\": \"${module.ncc_storage_secondary[0].private_endpoint_service}\",\"enabled\": true}"
  destroy_data = "{\"endpoint_service\": \"${module.ncc_storage_secondary[0].private_endpoint_service}\",\"enabled\": false}"

  depends_on   = [time_sleep.wait_connection_state_secondary]
}
