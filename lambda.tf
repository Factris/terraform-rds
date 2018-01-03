# The lambda function that copies the RDS snapshots on a daily basis
resource "aws_lambda_function" "backup_rds_daily" {
  filename         = "${path.module}/files/rds-copy-snapshots.py.zip"
  function_name    = "${var.environment}-rds-${aws_rds_cluster.cluster.id}-copy-snapshots-daily"
  role             = "${aws_iam_role.lamdba_rds_backup.arn}"
  runtime          = "python2.7"
  handler          = "rds-copy-snapshots.lambda_handler"
  source_code_hash = "${base64sha256(file(var.rds_backup_script))}"
  timeout          = 180
  memory_size      = 128
  environment      = {
    variables {
      RETENTION_DAYS = "${var.retention_count_daily}"
      RETENTION_WEEKS = "${var.retention_count_weekly}"
      RETENTION_MONTHS = "${var.retention_count_monthly}"
      REGION = "${data.aws_region.current.id}"
      CLUSTERS = "${aws_rds_cluster.cluster.id}"
    }
  }
}

# The corresponding lambda permission
resource "aws_lambda_permission" "allow_lamdbda_rds_backup_daily" {
  statement_id = "${var.environment}_AllowLamdba_to_backup_${aws_rds_cluster.cluster.id}_daily"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.backup_rds_daily.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.backup-daily.arn}"
}
