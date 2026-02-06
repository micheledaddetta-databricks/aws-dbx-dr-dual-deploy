resource "databricks_mws_networks" "this" {
  account_id         = var.databricks_account_id
  network_name       = "${var.prefix}-network-${var.suffix}"
  security_group_ids = [aws_security_group.default_sg.id]
  subnet_ids         = aws_subnet.db_private_subnet[*].id
  vpc_id             = aws_vpc.this.id

  vpc_endpoints {
    dataplane_relay = toset([databricks_mws_vpc_endpoint.relay_vpce.vpc_endpoint_id])
    rest_api        = toset([databricks_mws_vpc_endpoint.backend_rest_vpce.vpc_endpoint_id])
  }
}

resource "databricks_mws_storage_configurations" "this" {
  account_id                 = var.databricks_account_id
  bucket_name                = aws_s3_bucket.root_storage_bucket.bucket
  storage_configuration_name = "${var.prefix}-storage-${var.suffix}"
}

## Adding 20 second timer to avoid Failed credential validation check
resource "time_sleep" "wait" {
  create_duration = "20s"
  depends_on = [
    aws_iam_role_policy.cross_account_policy
  ]
}

resource "databricks_mws_credentials" "this" {
  role_arn         = aws_iam_role.cross_account_role.arn
  credentials_name = "${var.prefix}-creds-${var.suffix}"
  depends_on       = [time_sleep.wait]
}

resource "databricks_mws_workspaces" "this" {
  account_id     = var.databricks_account_id
  aws_region     = var.location
  workspace_name = "${var.prefix}-ws-${var.suffix}"

  credentials_id             = databricks_mws_credentials.this.credentials_id
  storage_configuration_id   = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id                 = databricks_mws_networks.this.network_id
  private_access_settings_id = databricks_mws_private_access_settings.pla.private_access_settings_id
  is_no_public_ip_enabled    = true

  token {
    comment = "Terraform token"
  }
}




