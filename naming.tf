locals {
  name_prefix = "tfc-agent-${var.environment}"

  base_commands = [
    "set -e",
    "echo 'TFC Agent starting...'",
    "echo \"Agent Name: $TFC_AGENT_NAME\"",
    "echo \"Environment: $ENVIRONMENT\"",
    "echo \"Region: $AWS_REGION\"",
    "apt-get update && apt-get install -y unzip curl make git zip"
  ]

  go_commands = [
    "wget https://go.dev/dl/go1.23.2.linux-amd64.tar.gz",
    "tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz",
    "echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc",
    "export PATH=$PATH:/usr/local/go/bin",
    "/usr/local/go/bin/go version"
  ]

  terraform_commands = var.install_terraform ? [
    "wget https://releases.hashicorp.com/terraform/${var.terraform_version}/terraform_${var.terraform_version}_linux_amd64.zip",
    "unzip terraform_${var.terraform_version}_linux_amd64.zip",
    "mv terraform /usr/local/bin/",
    "terraform version"
  ] : []

  custom_pre_build = var.pre_build_commands != null ? split("\n", var.pre_build_commands) : []

  agent_commands = [
    "echo 'Starting TFC Agent...'",
    "curl -fsSL -o tfc-agent.zip https://releases.hashicorp.com/tfc-agent/${var.tfc_agent_version}/tfc-agent_${var.tfc_agent_version}_linux_amd64.zip",
    "unzip tfc-agent.zip",
    "chmod +x tfc-agent",
    "exec ./tfc-agent"
  ]

  default_buildspec = yamlencode({
    version = "0.2"
    phases = {
      pre_build = {
        commands = compact(concat(
          local.base_commands,
          local.go_commands,
          local.terraform_commands,
          local.custom_pre_build
        ))
      }
      build = {
        commands = local.agent_commands
      }
    }
  })
  common_tags = merge(
    {
      Name        = local.name_prefix
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "TFC-Agent-Docker"
    },
    var.tags
  )
}
