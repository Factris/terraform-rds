# A cloud watch rule that triggers at 5:10
# This rule is used to trigger the backup script
resource "aws_cloudwatch_event_rule" "backup-daily" {
  name        = "${aws_rds_cluster.cluster.id}-backup-daily"
  description = "Backup RDS cluster ${aws_rds_cluster.cluster.id} daily"
  schedule_expression = "cron(10 5 * * ? *)"
}