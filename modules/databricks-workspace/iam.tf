resource "aws_iam_role" "cross_account_role" {
  name               = "${var.prefix}-crossaccount-${var.suffix}"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "cross_account_policy" {
  name   = "${var.prefix}-policy-${var.suffix}"
  role   = aws_iam_role.cross_account_role.id
  policy = data.databricks_aws_crossaccount_policy.this.json
}