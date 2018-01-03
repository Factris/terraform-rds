# AWS IAM role for the Lambda function that copies the RDS snapshot
resource "aws_iam_role" "lamdba_rds_backup" {
  name = "${var.environment}_lambda_assume_role_rds_${aws_rds_cluster.cluster.id}"
  assume_role_policy = "${data.aws_iam_policy_document.iam_lambda_assume_role_policy.json}"
}

# AWS IAM role policy for the Lambda function that copies the RDS snapshot
resource "aws_iam_role_policy" "lamdba_rds_role_policy" {
  name = "${var.environment}_lamdba_rds_${aws_rds_cluster.cluster.id}"
  role = "${aws_iam_role.lamdba_rds_backup.id}"
  policy = "${data.aws_iam_policy_document.iam_for_lambda_backup_policy.json}"
}