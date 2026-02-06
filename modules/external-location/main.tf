locals {
  uc_iam_role = "${var.prefix}-uc-access-${var.suffix}"
}

# Wait to prevent race condition between IAM role and external location validation
resource "time_sleep" "wait_60_seconds" {
  create_duration = "60s"
  depends_on      = [aws_iam_role_policy_attachment.external_data_access]
}

resource "databricks_storage_credential" "external" {
  name = "${var.prefix}-external-access-${var.suffix}"
  //cannot reference aws_iam_role directly, as it will create circular dependency
  aws_iam_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/${local.uc_iam_role}"
  }
  comment = "Managed by TF"
}

resource "aws_s3_bucket" "external" {
  bucket = "${var.prefix}-external-${var.suffix}"

  // destroy all objects with bucket destroy
  force_destroy = true
  tags = merge(var.tags, {
    Name = "${var.prefix}-external-${var.suffix}"
  })
}

resource "aws_s3_bucket_versioning" "external_versioning" {
  bucket = aws_s3_bucket.external.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "unity_catalog" {
  bucket                  = aws_s3_bucket.external.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.external]
}

resource "aws_iam_policy" "external_data_access" {
  name   = "${var.prefix}-policy-${var.suffix}"
  policy = data.databricks_aws_unity_catalog_policy.this.json
  tags   = var.tags
}

resource "aws_iam_role" "external_data_access" {
  name               = local.uc_iam_role
  assume_role_policy = data.databricks_aws_unity_catalog_assume_role_policy.this.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "external_data_access" {
  role       = aws_iam_role.external_data_access.name
  policy_arn = aws_iam_policy.external_data_access.arn
}

resource "databricks_external_location" "some" {
  name            = "${var.prefix}-${var.external_location_name}-${var.suffix}"
  url             = "s3://${aws_s3_bucket.external.id}"
  credential_name = databricks_storage_credential.external.id
  comment         = "Managed by TF"

}
