data "aws_iam_policy_document" "build_trust_policy" {
  statement {
    effect                      = "Allow"

    principals {
      type                      = "Service"
      identifiers               = ["codebuild.amazonaws.com"]
    }
    actions                     = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "build_role_policy" {
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


data "aws_iam_policy_document" "pipleine_trust_policy" {
  statement {
    effect                      = "Allow"

    principals {
      type                      = "Service"
      identifiers               = ["codepipeline.amazonaws.com"]
    }

    actions                     = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.example.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }
}