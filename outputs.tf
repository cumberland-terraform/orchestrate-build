output "build" {
    description                 = "Codebuild metadata"
    value                       = {
        cache                   = local.cache.location
        project                 = {
            id                  = aws_codebuild_project.this.id
            arn                 = aws_codebuild_project.this.arn
        }
    }
}