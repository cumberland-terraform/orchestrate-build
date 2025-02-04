resource "aws_iam_role" "roles" {
    for_each                        = local.roles

    name                            = each.value.name
    assume_role_policy              = each.value.assume_role_policy
}

resource "aws_iam_role_policy" "policies" {
    for_each                        = local.policies

    name                            = each.value.name
    policy                          = each.value.policy
    role                            = each.value.role
} 

resource "aws_codebuild_project" "build" {
    lifecycle {
        # NOTE: Tag calculations are interpretted as changes
        ignore_changes              = [ tags ]
    }

    name                            = local.build.name
    description                     = var.build.description
    build_timeout                   = local.platform_defaults.build_timeout
    service_role                    = aws_iam_role.roles["build"].arn
    tags                            = local.tags

    artifacts {
        type                        = var.build.artifact.type
    }

    cache   {
        type                        = local.build.cache.type
        location                    = local.build.cache.location
    }

    environment {
        compute_type                = var.build.environment.build_type
        image                       = var.build.environment.image
        type                        = var.build.environment.type
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
            group_name              = local.build.logs_config.group_name
            stream_name             = local.build.logs_config.stream_name
        }
    }

    source {
        type                        = var.build.source.type
        location                    = var.build.source.location
        git_clone_depth             = var.build.source.git_clone_depth

        dynamic "git_submodules_config" {
            for_each                = local.conditions.is_vcs && var.build.source.git_submodules_config != null? (
                                        toset([1]) 
                                    ): toset([])

            content {
                fetch_submodules    = var.build.source.git_submodules_config
            }
        }
    }
}

resource "aws_codepipeline" "pipeline" {
    lifecycle {
        # NOTE: Tag calculations are interpretted as changes
        ignore_changes              = [ tags ]
    }

    name                            = local.pipeline.name
    role_arn                        = aws_iam_role.roles["pipeline"].arn
    tags                            = local.tags

    artifact_store {
        location                    = module.artifacts.bucket[0].id
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
                input_artifacts     = try(stage.value.action.input_artifacts, null)
                output_artifacts    = try(stage.value.action.output_artifacts, null)
                configuration       = stage.value.action.configuration
            }
        }
    }
}

resource "aws_codestarconnections_connection" "source" {
    name                            = local.connection.name
    provider_type                   = var.connection.provider_type
}

resource "aws_sns_topic" "notifications" {
    lifecycle {
        # NOTE: Tag calculations are interpretted as changes
        ignore_changes              = [ tags ]
    }

    name                            = local.sns.topic
    tags                            = local.tags
}

resource "aws_sns_topic_subscription" "email_subscription" {
    for_each                        = { for index, email in var.topic.emails:
                                            index => email }
  
    topic_arn                       = aws_sns_topic.notifications.arn
    protocol                        = local.platform_defaults.topic.protocol
    endpoint                        = each.value
}

resource "aws_cloudwatch_event_rule" "rules" {
    for_each                        = local.rules

    description                     = each.value.description
    event_pattern                   = each.value.event_pattern
    name                            = each.value.name
    tags                            = local.tags
}

resource "aws_cloudwatch_event_target" "codebuild_success_target" {
    for_each                        = aws_cloudwatch_event.rule.rules

    rule                            = each.value.name
    target_id                       = join("-", ["sns", each.key, "target"])
    arn                             = aws_sns_topic.notifications.arn
}