module "tfc_agent" {
  source = "../../terraform-modules/tfc-agent-codebuild"

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