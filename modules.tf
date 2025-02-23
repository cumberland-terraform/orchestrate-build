module "platform" {
  source                = "github.com/cumberland-terraform/platform"
  
  platform              = var.platform
}

module "kms" {
  # META ARGUMENTS
  count                 = local.conditions.provision_kms_key ? 1 : 0
  source                = "github.com/cumberland-terraform/security-kms"
  # PLATFORM ARGUMENTS
  platform              = var.platform
  # MODULE ARGUMENTS
  kms                   = {
      alias_suffix      = var.suffix
  }
}

module "cache" {
  # META ARGUMENTS
  count                 = local.conditions.provision_cache ? 1 : 0
  source                = "github.com/cumberland-terraform/storage-s3.git"
  # PLATFORM ARGUMENTS
  platform              = var.platform
  # MODULE ARGUMENTS
  kms                   = local.kms
  s3                    = {
    purpose             = "Build cache for ${local.name}"
    suffix              = join("-", [var.suffix, "cache" ])
  }
}


module "artifacts" {
  # META ARGUMENTS
  source                = "github.com/cumberland-terraform/storage-s3.git"
  # PLATFORM ARGUMENTS
  platform              = var.platform
  # MODULE ARGUMENTS
  kms                   = local.kms
  s3                    = {
    purpose             = "Pipeline artifactory for ${local.name}"
    suffix              = join("-", [var.suffix, "artifacts"])
  }
}
