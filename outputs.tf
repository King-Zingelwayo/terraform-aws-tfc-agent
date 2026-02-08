output "codebuild_project_names" {
  description = "Names of CodeBuild projects"
  value       = aws_codebuild_project.agent[*].name
}

output "codebuild_project_arns" {
  description = "ARNs of CodeBuild projects"
  value       = aws_codebuild_project.agent[*].arn
}

output "codebuild_role_arn" {
  description = "ARN of CodeBuild IAM role"
  value       = var.agent_type == "codebuild" ? aws_iam_role.codebuild.arn : null
}

output "codebuild_role_name" {
  description = "Name of CodeBuild IAM role"
  value       = var.agent_type == "codebuild" ? aws_iam_role.codebuild.name : null
}

output "lambda_trigger_arn" {
  description = "ARN of Lambda trigger function"
  value       = var.agent_type == "codebuild" && var.enable_lambda_trigger && length(aws_lambda_function.trigger) > 0 ? aws_lambda_function.trigger[0].arn : null
}

output "lambda_trigger_name" {
  description = "Name of Lambda trigger function"
  value       = var.agent_type == "codebuild" && var.enable_lambda_trigger && length(aws_lambda_function.trigger) > 0 ? aws_lambda_function.trigger[0].function_name : null
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for CodeBuild"
  value       = var.agent_type == "codebuild" ? aws_cloudwatch_log_group.codebuild.name : null
}

output "ssm_parameter_name" {
  description = "Name of SSM parameter storing agent token"
  value       = aws_ssm_parameter.agent_token.name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = var.agent_type == "ecs" && length(aws_ecs_cluster.agent) > 0 ? aws_ecs_cluster.agent[0].name : null
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = var.agent_type == "ecs" && length(aws_ecs_service.agent) > 0 ? aws_ecs_service.agent[0].name : null
}