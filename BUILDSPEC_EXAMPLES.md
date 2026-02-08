# Buildspec Configuration Examples

## Architecture

The buildspec is composed of:

### Fixed Components (Always Included)
- Base setup commands (set -e, logging, apt packages)
- Go 1.23.2 installation
- TFC agent download and execution

### Optional Components
- Terraform installation (controlled by `install_terraform`)
- Custom pre-build commands (via `pre_build_commands`)
- Full custom buildspec (via `custom_buildspec`)

## Usage Examples

### 1. Default Configuration
```hcl
module "tfc_agent" {
  source = "./modules/terraform-tfc-agent"
  
  agent_type      = "codebuild"
  environment     = "dev"
  tfc_agent_token = var.tfc_agent_token
}
```
Includes: Base + Go + Terraform + TFC Agent

### 2. Without Terraform
```hcl
module "tfc_agent" {
  source = "./modules/terraform-tfc-agent"
  
  agent_type         = "codebuild"
  environment        = "dev"
  tfc_agent_token    = var.tfc_agent_token
  install_terraform  = false
}
```
Includes: Base + Go + TFC Agent

### 3. With Custom Pre-Build Commands
```hcl
module "tfc_agent" {
  source = "./modules/terraform-tfc-agent"
  
  agent_type      = "codebuild"
  environment     = "dev"
  tfc_agent_token = var.tfc_agent_token
  
  pre_build_commands = <<-EOT
    echo 'Installing additional tools...'
    apt-get install -y jq awscli
    aws --version
  EOT
}
```
Includes: Base + Go + Terraform + Custom Commands + TFC Agent

### 4. With AWS CLI and Python Tools
```hcl
module "tfc_agent" {
  source = "./modules/terraform-tfc-agent"
  
  agent_type      = "codebuild"
  environment     = "prod"
  tfc_agent_token = var.tfc_agent_token
  
  pre_build_commands = <<-EOT
    pip3 install boto3 requests
    apt-get install -y jq
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
  EOT
}
```

### 5. Fully Custom Buildspec
```hcl
module "tfc_agent" {
  source = "./modules/terraform-tfc-agent"
  
  agent_type           = "codebuild"
  environment          = "dev"
  tfc_agent_token      = var.tfc_agent_token
  use_custom_buildspec = true
  
  custom_buildspec = yamlencode({
    version = "0.2"
    phases = {
      install = {
        commands = [
          "echo 'Custom install phase'"
        ]
      }
      pre_build = {
        commands = [
          "echo 'Custom pre-build'"
        ]
      }
      build = {
        commands = [
          "echo 'Custom build'"
        ]
      }
    }
  })
}
```

## Command Execution Order

When using default buildspec:
1. Base commands (logging, apt-get)
2. Go installation
3. Terraform installation (if enabled)
4. Custom pre-build commands (if provided)
5. TFC agent download and execution

## Tips

- Use `pre_build_commands` for simple additions
- Use `custom_buildspec` for complete control
- Separate multiple commands with newlines in `pre_build_commands`
- Always test custom commands in a dev environment first
