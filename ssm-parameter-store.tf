# SSM Parameter for agent token
resource "aws_ssm_parameter" "agent_token" {
  name        = "/${local.name_prefix}/token"
  description = "Terraform Cloud agent token for ${var.environment}"
  type        = "SecureString"
  value       = var.tfc_agent_token

  tags = local.common_tags
}
