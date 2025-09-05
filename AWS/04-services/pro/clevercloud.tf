/*
  Dedicated resources used for CleverCloud 
  an IAM user using the same policy as the ECS role
*/

resource "aws_iam_user" "clevercloud" {
  name = "${var.product}-${var.application}-clevercloud-${var.environment}"
  path = "/"
}

resource "aws_iam_access_key" "clevercloud" {
  user = aws_iam_user.clevercloud.name
}

resource "aws_iam_user_policy_attachments_exclusive" "clevercloud" {
  user_name   = aws_iam_user.clevercloud.name
  policy_arns = [aws_iam_policy.pro_access.arn]
}
