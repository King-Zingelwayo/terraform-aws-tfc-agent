# Required Variables
variable "agent_type" {
  description = "Type of agent infrastructure (codebuild or ecs)"
  type        = string
  default     = "codebuild"

  validation {
    condition     = contains(["codebuild", "ecs"], var.agent_type)
    error_message = "Agent type must be either 'codebuild' or 'ecs'."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "tfc_agent_token" {
  description = "Terraform Cloud agent token"
  type        = string
  sensitive   = true
}

# CodeBuild Configuration
variable "agent_pool_size" {
  description = "Number of CodeBuild projects (agents) to create"
  type        = number
  default     = 1
}

variable "docker_image_name" {
  description = "Docker image name for CodeBuild"
  type        = string
  default     =  "hashicorp/tfc-agent:latest"
}
variable "compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_MEDIUM"

  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL",
      "BUILD_GENERAL1_MEDIUM",
      "BUILD_GENERAL1_LARGE",
      "BUILD_GENERAL1_2XLARGE"
    ], var.compute_type)
    error_message = "Invalid compute type."
  }
}

variable "codebuild_image" {
  description = "CodeBuild image to use"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "privileged_mode" {
  description = "Enable privileged mode for Docker builds"
  type        = bool
  default     = false
}

variable "build_timeout_minutes" {
  description = "Build timeout in minutes"
  type        = number
  default     = 480 # 8 hours max
}

variable "single_run_mode" {
  description = "Run agent in single-run mode (exit after one job)"
  type        = bool
  default     = false
}

variable "tfc_agent_version" {
  description = "TFC agent version to download"
  type        = string
  default     = "1.28.2"
}

# VPC Configuration (optional)
variable "vpc_config" {
  description = "VPC configuration for agents (CodeBuild and ECS)"
  type = object({
    vpc_id             = string
    subnets            = list(string)
    security_group_ids = list(string)
  })
  default = null
}

# Buildspec
variable "use_custom_buildspec" {
  description = "Use custom buildspec instead of default"
  type        = bool
  default     = false
}

variable "custom_buildspec" {
  description = "Custom buildspec YAML content"
  type        = string
  default     = null
}

variable "pre_build_commands" {
  description = "Additional commands to run in pre_build phase (newline-separated string or null)"
  type        = string
  default     = null

  validation {
    condition     = var.pre_build_commands == null || can(regex(".*", var.pre_build_commands))
    error_message = "pre_build_commands must be a valid string or null."
  }
}

variable "install_terraform" {
  description = "Install Terraform in the build environment"
  type        = bool
  default     = true
}

variable "terraform_version" {
  description = "Terraform version to install"
  type        = string
  default     = "1.7.0"
}

# Environment Variables
variable "environment_variables" {
  description = "Additional environment variables for CodeBuild"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "log_level" {
  description = "TFC agent log level"
  type        = string
  default     = "info"
}

# Triggering
variable "enable_lambda_trigger" {
  description = "Enable Lambda function to trigger CodeBuild"
  type        = bool
  default     = true
}

variable "enable_scheduled_trigger" {
  description = "Enable EventBridge scheduled trigger"
  type        = bool
  default     = true
}

variable "trigger_schedule" {
  description = "EventBridge schedule expression"
  type        = string
  default     = "rate(1 minute)" # Poll every minute
}

# ECS Configuration
variable "ecs_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "ecs_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 1024
}

variable "ecs_assign_public_ip" {
  description = "Assign public IP to ECS tasks"
  type        = bool
  default     = true
}

# Monitoring
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# IAM
variable "additional_iam_policies" {
  description = "Additional IAM policy ARNs to attach"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}