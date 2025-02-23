variable "platform" {
  description                     = "Platform metadata configuration object."
  type                            = object({
    client                        = string 
    environment                   = string
  })
}

variable "suffix" {
  description                     = "Naming suffix to apply to resources"
  type                            = string
}

variable "connection" {
  description                     = "Codestar Connection configuration object."
  type                            = object({
    provider_type                 = optional(string, "GitHub")
  })
  default                         = {
    provider_type                 = "GitHub"
  }
}

variable "build" {
  description                     = "Codebuild configuration object."
  type                            = object({
    artifact                      = optional(object({
      type                        = optional(string, "CODEPIPELINE")
    }), {
      type                        = "CODEPIPELINE"
    })
    
    cache                         = optional(object({
      type                        = optional(string, "NO_CACHE")
      location                    = optional(string, null)
    }), {
      type                        = "NO_CACHE"
      location                    = null
    })
    
    description                   = optional(string, "CodeBuild Projecct")

    environment                   = optional(object({
      build_type                  = optional(string, "BUILD_GENERAL1_SMALL")
      image                       = optional(string, "aws/codebuild/amazonlinux2-x86_64-standard:4.0")
      image_pull_credentials_type = optional(string, "CODEBUILD")
      type                        = optional(string, "LINUX_CONTAINER")
      environment_variables       = optional(list(object({
        name                      = string
        value                     = string
        type                      = optional(string, null)
      })), [])
    
    }), {
      build_type                  = "BUILD_GENERAL1_SMALL"
      image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
      image_pull_credentials_type = "CODEBUILD"
      type                        = "LINUX_CONTAINER"
    })

    source                        = optional(object({
      type                        = optional(string, "CODEPIPELINE")
      location                    = optional(string, null)
      git_clone_depth             = optional(number, 1)
      git_submodules_config       = optional(object({
        fetch_submodules          = bool
      }), null) 
    }), {
      type                        = "CODEPIPELINE"
      location                    = null
      git_clone_depth             = null
      git_submodules_config       = null
    })
        
    tags                          = optional(any, null)
  })
  default                         = {
    arficact                      = {
      type                        = "CODEPIPELINE"
    }
    cache                         = {
      type                        = "NO_CACHE"
    }
    environment                   = {
      build_type                  = "BUILD_GENERAL1_SMALL"
      image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
      image_pull_credentials_type = "CODEBUILD"
      type                        = "LINUX_CONTAINER"
    }
    source                        = {
      type                        = "CODEPIPELINE"
    }
  }
}

variable "pipeline" {
  description                     = "CodePipeline configuration object."
  type                            = object({

    source_stage                  = object({
      action                      = object({
        configuration             = object({
          FullRepositoryId        = string
          BranchName              = string
        })
      })
    })
  })
}

variable "secrets" {
  description                     = "List of SecretManager Secret IDs to inject into build environment."
  type                            = list(string)
  default                         = []
}


variable "kms" {
  description                     = "Key Management configuration object"
  type                            = object({
    aws_managed                   = optional(bool, true)
    id                            = optional(string, null)
    arn                           = optional(string, null)
  })
  default                         = {
    aws_managed                    = true
  }
}

variable "topic" {
  description                     = "SNS Topic configuration object."
  type                            = object({
    emails                        = list(string)
  })
  default                         = {
    emails                        = [ "chinchalinchin@gmail.com" ]
  }
}