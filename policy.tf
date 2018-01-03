# The policy for the lambda function
resource "aws_iam_policy" "lambda_rds_backup" {
  name        = "${var.environment}_lambda_rds_${aws_rds_cluster.cluster.id}_backup"
  policy = "${data.aws_iam_policy_document.iam_for_lambda_backup_policy.json}"
}

# The policy document for the lambda function
data "aws_iam_policy_document" "iam_for_lambda_backup_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }

  statement {
    actions = [
      "rds:CopyDBClusterSnapshot",
      "rds:DeleteDBClusterSnapshot",
    ]

    resources = [
      "arn:aws:rds:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:cluster-snapshot:*",
    ]
  }

  statement {
    actions = [
      "rds:ListTagsForResource",
      "rds:DescribeDBClusters",
      "rds:DescribeDBClusterSnapshots",
    ]

    resources = [
      "arn:aws:rds:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:cluster:*"
    ]
  }

  statement {
    actions = [
      "logs:*"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}



