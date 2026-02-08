# CodeBuild Project for TFC Agent
resource "aws_codebuild_project" "agent" {
  count         = var.agent_type == "codebuild" ? var.agent_pool_size : 0
  name          = "${local.name_prefix}-${count.index + 1}"
  description   = "TFC Agent ${count.index + 1} for ${var.environment}"
  build_timeout = var.build_timeout_minutes
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  # Use custom Docker image or managed image
  environment {
    compute_type    = var.compute_type
    image           = var.codebuild_image
    type            = "LINUX_CONTAINER"
    privileged_mode = var.privileged_mode

    # Environment variables
    dynamic "environment_variable" {
      for_each = merge(
        {
          TFC_AGENT_TOKEN     = aws_ssm_parameter.agent_token.name
          TFC_AGENT_NAME      = "${local.name_prefix}-codebuild-${count.index + 1}"
          TFC_AGENT_LOG_LEVEL = var.log_level
          TFC_AGENT_SINGLE    = var.single_run_mode ? "true" : "false"
          AWS_REGION          = data.aws_region.current.id
          ENVIRONMENT         = var.environment
        },
        var.environment_variables
      )

      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = environment_variable.key == "TFC_AGENT_TOKEN" ? "PARAMETER_STORE" : "PLAINTEXT"
      }
    }
  }

  # VPC Configuration (optional)
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []

    content {
      vpc_id             = vpc_config.value.vpc_id
      subnets            = vpc_config.value.subnets
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = var.use_custom_buildspec && var.custom_buildspec != null ? var.custom_buildspec : local.default_buildspec
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "agent-${count.index + 1}"
    }

    s3_logs {
      status = "DISABLED"
    }
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }


  tags = merge(
    local.common_tags,
    {
      AgentNumber = count.index + 1
    }
  )
}
