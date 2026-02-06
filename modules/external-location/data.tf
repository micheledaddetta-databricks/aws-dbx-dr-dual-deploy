data "databricks_aws_unity_catalog_assume_role_policy" "this" {
  aws_account_id = var.aws_account_id
  role_name      = local.uc_iam_role
  external_id    = databricks_storage_credential.external.aws_iam_role[0].external_id
}

data "databricks_aws_unity_catalog_policy" "this" {
  aws_account_id = var.aws_account_id
  bucket_name    = aws_s3_bucket.external.id
  role_name      = local.uc_iam_role
}