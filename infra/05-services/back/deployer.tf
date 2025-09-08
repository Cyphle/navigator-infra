data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_policy" "deployer" {
  name        = "${var.project_name}-backend-deployer-${var.environment}"
  path        = "/"
  description = "Github access to deploy ${var.project_name} front on AWS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:ListImages",
        "ecr:ListTagsForResource",
        "ecr:PutImage",
        "ecr:TagResource",
        "ecr:UntagResource",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "${data.aws_ecr_repository.backend.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:DescribeRegistry"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action":[
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"
      ],
      "Resource":"*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "iam:PassRole"
      ],
      "Resource": [
        "${aws_iam_role.backend_taskexec.arn}",
        "${aws_iam_role.backend_task.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices"
      ],
      "Resource": [
        "${aws_ecs_service.backend.id}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "deployer" {
  name                 = "${var.project_name}-backend-deployer-${var.region}-${var.environment}"
  description          = "Role used by Github OIDC provider to deploy backend"
  assume_role_policy   = data.aws_iam_policy_document.deployer_assume_role.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "deployer_assume_role" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      variable = "token.actions.githubusercontent.com:aud"
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      variable = "token.actions.githubusercontent.com:sub"
      test     = "StringLike"
      values = [
        for claim_suffix in var.github_claim_suffixes : "repo:${var.github_organization}/${var.github_repository}:${claim_suffix}"
      ]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role_policy_attachment" "deployer" {
  role       = aws_iam_role.deployer.id
  policy_arn = aws_iam_policy.deployer.arn
}
