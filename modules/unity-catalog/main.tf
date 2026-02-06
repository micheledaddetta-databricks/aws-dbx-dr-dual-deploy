// Create UC metastore
resource "databricks_metastore" "this" {
  provider      = databricks.account
  name          = "${var.prefix}-primary-metastore-${var.suffix}"
  region        = var.location
  force_destroy = true
}

resource "databricks_metastore_assignment" "default_metastore" {
  provider     = databricks.workspace
  workspace_id = var.workspace_id
  metastore_id = databricks_metastore.this.id
}

resource "databricks_default_namespace_setting" "this" {
  provider = databricks.workspace
  namespace {
    value = "main"
  }
}