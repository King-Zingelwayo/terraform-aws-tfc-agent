module "tfc_agent" {
  source  = "King-Zingelwayo/tfc-agent/aws"
  version = "1.0.1"

  environment     = "prod"
  tfc_agent_token = var.tfc_agent_token
  
  agent_pool_size = 5
  compute_type    = "BUILD_GENERAL1_LARGE"
  
  # VPC configuration for private resources
  vpc_config = {
    vpc_id             = module.vpc.vpc_id
    subnets            = module.vpc.private_subnets
    security_group_ids = [aws_security_group.tfc_agent.id]
  }
  
  # Custom environment
  environment_variables = {
    GO_VERSION   = "1.21"
    NODE_VERSION = "18"
  }
  
  # Additional permissions
  additional_iam_policies = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
  
  tags = {
    Team        = "Platform"
    CostCenter  = "Engineering"
  }
}