# Create Network Connectivity Config at account level
resource "databricks_mws_network_connectivity_config" "this" {
  name   = "${var.prefix}-ncc-${var.suffix}"
  region = var.location
}

# Wait for NCC to propagate
resource "time_sleep" "wait_for_ncc" {
  depends_on      = [databricks_mws_network_connectivity_config.this]
  create_duration = "10s"
}

# Bind NCC to the workspace
resource "databricks_mws_ncc_binding" "this" {
  network_connectivity_config_id = databricks_mws_network_connectivity_config.this.network_connectivity_config_id
  workspace_id                   = var.workspace_id
  depends_on                     = [time_sleep.wait_for_ncc]
}

# Create private endpoint rule for each storage account
resource "databricks_mws_ncc_private_endpoint_rule" "storage" {
  network_connectivity_config_id = databricks_mws_network_connectivity_config.this.network_connectivity_config_id
  endpoint_service               = "com.amazonaws.${var.location}.s3"
  resource_names                 = [for k, bucket in var.s3_buckets : bucket.id]

  depends_on = [databricks_mws_network_connectivity_config.this]
}


