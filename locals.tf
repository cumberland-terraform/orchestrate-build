locals {
    ## PLATFORM DEFAULTS
    #   These are platform specific configuration options. They should only need
    #       updated if the platform itself changes.   
    platform_defaults           = {
        build_timeout           = 5

        pipeline                = {
            artifact_store      = {
                type            = "S3"
            }
            encryption_key      = {
                type            = "KMS"
            }
        }
        topic                   = {
            protocol            = "email"
        }

        aws_managed_key_alias   = "alias/aws/s3"
        secret_key_alias        = "alias/aws/secretsmanager"
    }

     ## CONDITIONS
    #   Configuration object containing boolean calculations that correspond
    #       to different deployment configurations.
    conditions                      = {
        attach_secret_policy        = length(var.secrets) > 0
        provision_kms_key           = var.kms == null
        provision_cache             = var.build.cache.type == "S3"&& (
                                        var.build.cache.location == null
                                    )
        provision_pipeline          = var.build.source.type == "CODEPIPELINE"
        is_vcs                      = contains(
                                        [ "CODECOMMIT", "GITHUB", "GITHUB_ENTERPRISE"],
                                        var.build.source.type
                                    )
    }

    ## NAMING CONVENTION
    #   String that is appended to all resource names
    name                            = upper(join("-", [module.platform.prefix,
                                        var.suffix
                                    ]))

    ## CALCULATED PROPERTIES
    #   Variables that change based on the deployment configuration. 
    build                           = {
        cache                       = local.conditions.provision_cache ? {
            type                    = var.build.cache.type
            location                = module.cache[0].bucket[0].id
        } : var.build.cache

        name                        = upper(join("-", [
                                        "BUILD",
                                        local.name
                                    ]))

        logs_config                 = {
            group_name              = lower(join("-", [ local.name, "group" ]))
            stream_name             = lower(join("-", [ local.name, "stream" ]))
        }

    }

    connection                      = {
        name                        = upper(join("-", [
                                        "CONNECT",
                                        local.name
                                    ]))
    }

    kms                             = local.conditions.provision_kms_key ? (
                                        module.kms[0].key
                                    ) : !var.kms.aws_managed ? (
                                        var.kms
                                    ) : {
                                        id = data.aws_kms_key.kms[0].id
                                        arn = data.aws_kms_key.kms[0].arn
                                        aws_managed = true
                                    }

    pipeline                        = {
        name                        = upper(join("-", [
                                        "PIPE",
                                        local.name
                                    ]))
        stages                      = [{
            name                    = "Source"
            action                  = {
                name                = "Source"
                category            = "Source"
                owner               = "AWS"
                provider            = "CodeStarSourceConnection"
                version             = "1"
                output_artifacts    = [ "source_output" ]
                configuration       = {
                    ConnectionArn   = aws_codestarconnections_connection.source.arn
                    FullRepositoryId= var.pipeline.source_stage.action.configuration.FullRepositoryId
                    BranchName      = var.pipeline.source_stage.action.configuration.BranchName
                }
            }
        }, {
            name                    = "Build"
            action                  = {
                name                = "Build"
                category            = "Build"
                owner               = "AWS"
                provider            = "CodeBuild"
                version             = "1"
                input_artifacts     = [ "source_output" ]
                output_artifacts    = [ "build_output" ]
                configuration       = {
                    ProjectName     = aws_codebuild_project.build.name
                }
            }
        }]
    }

    policies                        = {
        build                       = {
            name                    = upper(join("-", [
                                        "IMP",
                                        "BUILD",
                                        local.name
                                    ]))
            policy                  = data.aws_iam_policy_document.build_role_policy.json
            role                    = aws_iam_role.roles["build"].id
        }
        events                      = {
            name                    = upper(join("-", [
                                        "IMP",
                                        "EVENTS",
                                        local.name
                                    ]))
            policy                  = data.aws_iam_policy_document.eventbridge_role_policy.json
        }
        pipeline                    = {
            name                    = upper(join("-", [
                                        "IMP",
                                        "PIPE",
                                        local.name
                                    ]))
            policy                  = data.aws_iam_policy_document.pipeline_role_policy.json
            role                    = aws_iam_role.roles["pipeline"].id
        }

    }

    roles                           = {
        build                       = {
            assume_role_policy      = data.aws_iam_policy_document.build_trust_policy.json
            name                    = upper(join("-", [
                                        "IMR",
                                        "BUILD",
                                        local.name
                                    ]))
        }
        events                      = {
            assume_role_policy      = data.aws_iam_policy_document.eventbridge_trust_policy.json
            name                    = upper(join("-", [
                                        "IMR",
                                        "EVENTS",
                                        local.name
                                    ]))
        }
        pipeline                    = {
            assume_role_policy      = data.aws_iam_policy_document.pipeline_trust_policy.json
            name                    = upper(join("-", [
                                        "IMR",
                                        "PIPE",
                                        local.name
                                    ]))
        }
    }

    rules                           = {
        success                     = {
            description             = "Triggered on successful CodeBuild builds."
            event_pattern           = templatefile("${path.module}/rules/success.json", {
                project                 = aws_codebuild_project.build.id
            })
            name                    = upper(join("-", [
                                        "EVENT",
                                        local.name,
                                        "SUCCESS"
                                    ]))
        }
        failure                     = {
            description             = "Triggered on failed CodeBuild builds."
            event_pattern           = templatefile("${path.module}/rules/failure.json", {
                project                 = aws_codebuild_project.build.id
            })
            name                    = upper(join("-", [
                                        "EVENT",
                                        local.name,
                                        "SUCCESS" 
                                    ]))
        }
    }

    sns                             = {
        topic                       = upper(join("-", [local.name, "notifications"]))
    }

    tags                            = merge(var.build.tags, module.platform.tags)
}