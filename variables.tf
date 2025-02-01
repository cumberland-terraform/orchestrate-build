variable "platform" {
  description                   = "Platform metadata configuration object."
  type                          = object({
    client                      = string 
    environment                 = string
  })
}

variable "build" {
  description                   = "Codebuild configuration object."
  type                          = object({
    source                      = object({
      type                      = string
      location                  = string 
      git_clone_depth           = optional(number ,1)
      git_submodules_config     = optional(object({
        fetch_submodules        = optional(bool, true)
      }), {
        fetch_submodules        = true
      }) 
    })
    
    suffix                      = string
    
    artifact                    = optional(object({
      type                      = optional(string, "NO_ARTIFACTS")
    }), {
      type                      = "NO_ARTIFACTS"
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

    logs_config                   = optional(object({
      group_name                  = string
      stream_name                 = string
    }), null)

    tags                          = optional(any, null)

    kms_key                       = optional(object({
      aws_managed                 = optional(bool, false)
      id                          = optional(string, null)
      arn                         = optional(string, null)
    }), null)
  })
}
