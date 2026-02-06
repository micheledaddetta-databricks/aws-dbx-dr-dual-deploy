output "bucket_id" {
  description = "S3 bucket ID of the external location"
  value       = aws_s3_bucket.external.id
}

output "bucket_arn" {
  description = "S3 bucket ARN of the external location"
  value       = aws_s3_bucket.external.arn
}

output "bucket_region" {
  description = "S3 bucket region of the external location"
  value       = aws_s3_bucket.external.region
}

output "external_location_name" {
  description = "Name of the Unity Catalog external location"
  value       = databricks_external_location.some.name
}

output "external_location_url" {
  description = "URL of the Unity Catalog external location"
  value       = databricks_external_location.some.url
}

output "storage_credential_name" {
  description = "Name of the storage credential"
  value       = databricks_storage_credential.external.name
}
