data "aws_iam_policy_document" "allow_access_from_serverless" {
  for_each = var.s3_buckets

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