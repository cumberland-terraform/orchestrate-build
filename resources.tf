resource "aws_iam_role" "build" {
    name                            = local.role.name
    assume_role_policy              = data.aws_iam_policy_document.build_trust_policy.json
}

resource "aws_iam_role" "pipeline" {
  name                              = local.role.pipeline
  assume_role_policy                = data.aws_iam_policy_document.pipleine_trust_policy.json
}

resource "aws_iam_role_policy" "build" {
    name                            = local.policies.build
    role                            = aws_iam_role.build.id
    policy                          = data.aws_iam_policy_document.build_role_policy.json
}

resource "aws_iam_role_policy" "pipeline" {
    name                            = local.policies.pipeline
    role                            = aws_iam_role.pipeline.id
    policy                          = data.aws_iam_policy_document.pipeline_role_policy.json
}

resource "aws_codebuild_project" "build" {
    name                            = local.build.name
    description                     = var.build.description
    build_timeout                   = local.platform_defaults.build_timeout
    service_role                    = aws_iam_role.build.arn
    tags                            = local.tags

    artifacts {
        type                        = var.artifact.type
    }

    cache   {
        type                        = local.cache.type
        location                    = local.cache.location
    }


    environment {
        compute_type                = var.build.environment.build_type
        image                       = var.build.environment.image
        type                        = var.build.type
        image_pull_credentials_type = var.build.environment.image_pull_credentials_type

        dynamic "environment_variable" {
            for_each                = { for index, env in var.build.environment.environment_variables:
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

        dynamic "git_submodules_config" {
            for_each                = local.conditions.is_vcs && var.build.source.git_submodules_config ? (
                                        toset([1]) 
                                    ): toset([])

            content {
                fetch_submodules    = var.build.source.git_submodules_config
            }
        }
    }
}

resource "aws_codepipeline" "pipeline" {
    name                            = local.pipeline.name
    role_arn                        = aws_iam_role.pipeline.arn

    artifact_store {
        location                    = module.artifacts.bucket[0].arn
        type                        = local.platform_defaults.pipeline.artifact_store.type

        encryption_key {
            id                      = local.kms.id
            type                    = local.platform_defaults.pipeline.encryption_key.type
        }
    }

    dynamic "stage" {
        for_each                    = { for i, stage in local.pipeline.stages: 
                                        i => stage }
        
        content {
            name                    = stage.value.name

            action {
                name                = stage.value.action.name
                category            = stage.value.action.category
                owner               = stage.value.action.owner
                provider            = stage.value.action.provider
                version             = stage.value.action.version
                output_artifacts    = stage.value.action.output_artifacts
                configuration       = stage.value.action.configuration
            }
        }
    }
}

resource "aws_codestarconnections_connection" "connect" {
    name                            = local.connection.name
    provider_type                   = var.connection.provider_type
}