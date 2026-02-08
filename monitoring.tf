# CloudWatch Log Group for CodeBuild
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}
