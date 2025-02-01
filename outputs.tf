output "build" {
    description                 = "Codebuild metadata"
    value                       = {
        cache                   = local.cache
        project                 = {
            id                  = aws_codebuild_project.build.id
            arn                 = aws_codebuild_project.build.arn
        }
    }
}