# The KMS key that is used by the RDS cluster to encrypt data at rest
resource "aws_kms_key" "kms_key" {
  description       = "${var.kms_description}"
  policy            = "${data.aws_iam_policy_document.kms_policy.json}"
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.kms_purpose}-${var.environment}"
  target_key_id = "${aws_kms_key.kms_key.key_id}"
}

