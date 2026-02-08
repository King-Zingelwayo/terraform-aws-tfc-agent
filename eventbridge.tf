# EventBridge rule for scheduled polling
resource "aws_cloudwatch_event_rule" "trigger" {
  count               = var.agent_type == "codebuild" && var.enable_scheduled_trigger ? 1 : 0
  name                = "${local.name_prefix}-trigger"
  description         = "Trigger TFC agent CodeBuild projects"
  schedule_expression = var.trigger_schedule

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  count     = var.agent_type == "codebuild" && var.enable_scheduled_trigger && var.enable_lambda_trigger ? 1 : 0
  rule      = aws_cloudwatch_event_rule.trigger[0].name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.trigger[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.agent_type == "codebuild" && var.enable_scheduled_trigger && var.enable_lambda_trigger ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger[0].arn
}