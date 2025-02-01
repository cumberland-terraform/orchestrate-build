locals {
    ## PLATFORM DEFAULTS
    #   These are platform specific configuration options. They should only need
    #       updated if the platform itself changes.   
    platform_defaults           = {
        build_timeout           = 5
    }

     ## CONDITIONS
    #   Configuration object containing boolean calculations that correspond
    #       to different deployment configurations.
    conditions                  = {
        provision_kms_key       = var.build.kms_key == null
        provision_cache         = var.build.cache.type == "S3"&& (
                                    var.build.cache.location == null
                                )
    }

    ## CALCULATED PROPERTIES
    #   Variables that change based on the deployment configuration. 
    kms_key_id                  = local.conditions.provision_kms_key ? (
                                    module.kms[0].key.id
                                ) : !var.secret.kms_key.aws_managed ? (
                                    var.secret.kms_key.id
                                ) : null

    cache                       = local.conditions.provision_cache ? {
        type                    = var.build.cache
        location                = module.cache[0].bucket[0].id
    } : var.build.cache


    logs_config                 = var.build.logs_config == null ? {
        group_name              = join("-", [local.name, "group"])
    } : var.build.logs_config

    tags                        = merge(var.build.tags, module.platform.tags)

    name                        = upper(join("-", [
                                    "BUILD",
                                    module.platform.prefix,
                                    var.build.suffix
                                ]))

    role                        = {
        name                    = upper(join("-", [
                                    "IAM",
                                    local.name
                                ]))
    }


}