output "source" {
    description                 = "CodeStar metadata"
    value                       = aws_codestarconnections_connection.source
}

output "build" {
    description                 = "CodeBuild metadata"
    value                       = {
        cache                   = local.build.cache
        project                 = aws_codebuild_project.build
    }
}

output "pipeline" {
    description                 = "CodePipeline metadata"
    value                       = {
        artifacts               = module.artifacts.bucket
        pipeline                = aws_codepipeline.pipeline
    }
}

output "kms" {
    description                 = "KMS metadata"
    value                       = local.kms
}