resource "aws_iam_role" "this" {
    name                            = local.role.name
    assume_role_policy              = data.aws_iam_policy_document.trust_policy.json
}


resource "aws_iam_role_policy" "this" {
    role                            = aws_iam_role.example.name
    policy                          = data.aws_iam_policy_document.role_policy.json
}

resource "aws_codebuild_project" "this" {
    name                            = local.name
    description                     = var.build.description
    build_timeout                   = local.platform_defaults.build_timeout
    service_role                    = aws_iam_role.this.arn
    tags                            = local.tags

    artifacts {
        type                        = var.artifact.type
    }

    cache   {
        type                        = local.cache.type
        location                    = local.cache.location
    }


    environment {
        compute_type                = var.environment.build_type
        image                       = var.environment.image
        type                        = var.environment.type
        image_pull_credentials_type = var.environment.image_pull_credentials_type

        dynamic "environment_variable" {
            for_each                = { for index, env in var.environment.environment_variables:
                                            index => env }

            content {
                name                = environment_variable.value.name
                value               = environment_variable.value.value
            }
        }
    }

    logs_config {
        cloudwatch_logs {
            group_name              = local.logs_config.group_name
            stream_name             = local.logs_config.stream_name
        }
    }

    source {
        type                        = var.build.source.type
        location                    = var.build.source.location
        git_clone_depth             = var.build.source.git_clone_depth

        git_submodules_config {
            fetch_submodules        = var.build.source.git_submodules_config.fetch_submodules
        }
    }

}
