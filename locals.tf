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
    }

     ## CONDITIONS
    #   Configuration object containing boolean calculations that correspond
    #       to different deployment configurations.
    conditions                      = {
        provision_kms_key           = var.build.kms_key == null
        provision_cache             = var.build.cache.type == "S3"&& (
                                        var.build.cache.location == null
                                    )
        provision_pipeline          = var.build.source.type == "CODEPIPELINE"

        is_vcs                      = contains(
                                        [ "CODECOMMIT", "GITHUB", "GITHUB_ENTERPRISE"],
                                        var.build.source.type
                                    )
    }

    ## CALCULATED PROPERTIES
    #   Variables that change based on the deployment configuration. 
    kms                             = local.conditions.provision_kms_key ? (
                                        module.kms[0].key
                                    ) : !var.build.kms_key.aws_managed ? (
                                        var.build.kms_key
                                    ) : null

    cache                           = local.conditions.provision_cache ? {
        type                        = var.build.cache
        location                    = module.cache[0].bucket[0].id
    } : var.build.cache


    environment_variables           = concat(
                                        var.environment.environment_variables, 
                                        [ for secret in var.secrets: {
                                            name = secret
                                            value = "${module.platform.arn.sm.secret}:${secret}"
                                            type = "PARAMETER_STORE"
                                        }]
                                    )

    logs_config                     = var.build.logs_config == null ? {
        group_name                  = join("-", [local.name, "group"])
    } : var.build.logs_config

    tags                            = merge(var.build.tags, module.platform.tags)

    name                            = upper(join("-", [module.platform.prefix,
                                        var.build.suffix
                                    ]))

    connection                      = {
        name                        = upper(join("-", [
                                        "CONNECT",
                                        local.name
                                    ]))
    }
    
    build                           = {
        name                        = upper(join("-", [
                                        "BUILD",
                                        local.name
                                    ]))
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
                    FullRepositoryId= var.pipeline.source_stage.FullRepositoryId
                    BranchName      = var.pipeline.source_stage.BranchName
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

    roles                           = {
        build                       = upper(join("-", [
                                        "IMR",
                                        local.build.name
                                    ]))
        pipeline                    = upper(join("-", [
                                        "IMR",
                                        local.pipeline.name
                                    ]))
    }

    policies                        = {
        build                       = upper(join("-", [
                                            "IMP",
                                            local.build.name
                                        ]))
        pipeline                    = upper(join("-", [
                                        "IMP",
                                        local.pipeline.name
                                    ]))
    }
}