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

  statement {
    effect                      = "ALLOW"
    actions                     = [
                                  "secretsmanager:GetSecretValue",
                                  "secretsmanager:DescribeSecret"
                                ]
    resources                   = [ for secret in var.secrets: 
                                    "${module.platform.arn.sm.secret}:${secret}"]
  }
}


data "aws_iam_policy_document" "pipeline_trust_policy" {
  statement {
    effect                      = "Allow"

    principals {
      type                      = "Service"
      identifiers               = ["codepipeline.amazonaws.com"]
    }

    actions                     = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "pipeline_policy" {
  statement {
    effect                    = "Allow"
    actions                   = [
                                "s3:GetObject",
                                "s3:GetObjectVersion",
                                "s3:GetBucketVersioning",
                                "s3:PutObjectAcl",
                                "s3:PutObject",
                              ]
    resources                 = [
                                module.artifacts.bucket[0].arn,
                                "${module.artifacts.bucket[0].arn}/*"
                              ]
  }
  statement {
    effect                    = "Allow"
    actions                   = [ 
                                "kms:Encrypt",
                                "kms:Decrypt",
                                "kms:GenerateDataKey*",
                                "kms:DescribeKey"
                              ]
    resources                 = [ local.kms.arn ]
  }
  
  statement {
    effect                    = "Allow"
    actions                   = [ "codestar-connections:UseConnection" ]
    resources                 = [ aws_codestarconnections_connection.connect.arn ]
  }

  statement {
    effect                    = "Allow"
    actions                   = [
                                "codebuild:BatchGetBuilds",
                                "codebuild:StartBuild",
                              ]
    resources                 = [ aws_codebuild_project.build.arn ]
  }
}