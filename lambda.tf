# Lambda function to trigger CodeBuild
data "archive_file" "lambda_trigger" {
  count       = var.agent_type == "codebuild" && var.enable_lambda_trigger ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/lambda-trigger.zip"

  source {
    content  = file("${path.module}/lambda/trigger/index.py")
    filename = "index.py"
  }
}

resource "aws_lambda_function" "trigger" {
  count            = var.agent_type == "codebuild" && var.enable_lambda_trigger ? 1 : 0
  filename         = data.archive_file.lambda_trigger[0].output_path
  function_name    = "${local.name_prefix}-trigger"
  role             = aws_iam_role.lambda_trigger[0].arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_trigger[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 60

  environment {
    variables = {
      CODEBUILD_PROJECTS = jsonencode(aws_codebuild_project.agent[*].name)
      ENVIRONMENT        = var.environment
    }
  }

  tags = local.common_tags
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_trigger" {
  count             = var.agent_type == "codebuild" && var.enable_lambda_trigger ? 1 : 0
  name              = "/aws/lambda/${local.name_prefix}-trigger"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}