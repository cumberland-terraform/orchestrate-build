data "aws_iam_policy_document" "trust_policy" {
  statement {
    effect                      = "Allow"

    principals {
      type                      = "Service"
      identifiers               = ["codebuild.amazonaws.com"]
    }
    actions                     = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "role_policy" {
  statement {
    effect                      = "Allow"

    actions                     = [
                                    "logs:CreateLogGroup",
                                    "logs:CreateLogStream",
                                    "logs:PutLogEvents",
                                ]

    resources                   = ["*"]
  }
}