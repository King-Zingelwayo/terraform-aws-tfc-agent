module "tfc_agent" {
  source  = "King-Zingelwayo/tfc-agent/aws"
  version = "1.0.1"

  environment     = "dev"
  tfc_agent_token = var.tfc_agent_token
  
  # Create 3 agent projects
  agent_pool_size = 3
  
  # Use medium compute
  compute_type = "BUILD_GENERAL1_MEDIUM"
  
  # Poll every minute
  enable_scheduled_trigger = true
  trigger_schedule         = "rate(1 minute)"
  
  # Run in single mode (exit after one job)
  single_run_mode = true
}