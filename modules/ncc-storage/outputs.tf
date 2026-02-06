output "ncc_id" {
  description = "ID of the Network Connectivity Config"
  value       = databricks_mws_network_connectivity_config.this.network_connectivity_config_id
}

output "ncc_name" {
  description = "Name of the Network Connectivity Config"
  value       = databricks_mws_network_connectivity_config.this.name
}

output "private_endpoint_rule_id" {
  description = "Private endpoint rule ID"
  value       = databricks_mws_ncc_private_endpoint_rule.storage.rule_id
}

output "private_endpoint_service" {
  description = "Private endpoint rule service"
  value       = databricks_mws_ncc_private_endpoint_rule.storage.endpoint_service
}

