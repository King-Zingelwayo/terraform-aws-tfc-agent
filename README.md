# Terraform Cloud Agent Module

Deploy Terraform Cloud agents using AWS CodeBuild or ECS Fargate.

## Agent Types

**CodeBuild**: Serverless, pay-per-use, triggered on-demand  
**ECS Fargate**: Always-on containers, predictable performance

## Usage

### CodeBuild Agent

```hcl
module "tfc_agent" {
  source = "./modules/terraform-tfc-agent"

  agent_type      = "codebuild"
  environment     = "dev"
  tfc_agent_token = var.tfc_agent_token
  agent_pool_size = 3
  compute_type    = "BUILD_GENERAL1_SMALL"
  
  enable_scheduled_trigger = true
  trigger_schedule         = "rate(1 minute)"
  single_run_mode          = true
}
```

### CodeBuild Agent with VPC

```hcl
module "tfc_agent" {
  source = "./modules/terraform-tfc-agent"

  agent_type      = "codebuild"
  environment     = "dev"
  tfc_agent_token = var.tfc_agent_token
  
  vpc_config = {
    vpc_id             = "vpc-12345678"
    subnets            = ["subnet-abc123", "subnet-def456"]
    security_group_ids = ["sg-12345678"]
  }
}
```

### ECS Fargate Agent

```hcl
module "tfc_agent" {
  source = "./modules/terraform-tfc-agent"

  agent_type      = "ecs"
  environment     = "prod"
  tfc_agent_token = var.tfc_agent_token
  agent_pool_size = 2
  
  ecs_cpu    = 1024
  ecs_memory = 2048
  
  vpc_config = {
    vpc_id             = "vpc-12345678"
    subnets            = ["subnet-abc123", "subnet-def456"]
    security_group_ids = ["sg-12345678"]
  }
}
```

## Required Variables

- `agent_type`: "codebuild" or "ecs"
- `environment`: dev/staging/prod
- `tfc_agent_token`: Terraform Cloud agent token

## VPC Configuration

### CodeBuild (Optional)
VPC configuration is **optional** for CodeBuild. Only specify if you need agents to run within your private network to access internal resources.

**Without VPC** (default): Agents run in AWS-managed network with internet access.

**With VPC**: Agents run in your private subnets. Ensure subnets have:
- NAT Gateway for internet access (to reach Terraform Cloud)
- Or VPC endpoints for AWS services

### ECS (Required)
VPC configuration is **required** for ECS Fargate. You must specify:
- `vpc_id`: Your VPC ID
- `subnets`: Private or public subnet IDs
- `security_group_ids`: Security groups allowing outbound HTTPS (443) to Terraform Cloud

**Public subnets**: Set `ecs_assign_public_ip = true` (default)
**Private subnets**: Requires NAT Gateway or VPC endpoints for internet access

### Configuration Object

```hcl
vpc_config = {
  vpc_id             = "vpc-12345678"
  subnets            = ["subnet-abc123", "subnet-def456"]
  security_group_ids = ["sg-12345678"]
}
```

## Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `agent_pool_size` | 2 | Number of agents |
| `compute_type` | BUILD_GENERAL1_MEDIUM | CodeBuild size |
| `ecs_cpu` | 512 | ECS CPU units |
| `ecs_memory` | 1024 | ECS memory (MB) |
| `single_run_mode` | false | Exit after one job |
| `trigger_schedule` | rate(1 minute) | EventBridge schedule |

## Buildspec Customization

See [BUILDSPEC_EXAMPLES.md](./BUILDSPEC_EXAMPLES.md) for:
- Default buildspec structure
- Adding custom pre-build commands
- Installing additional tools
- Complete buildspec override examples

## Cost Analysis

### Default Configurations

**CodeBuild**: `BUILD_GENERAL1_MEDIUM` (3 GB memory, 2 vCPUs)  
**ECS Fargate**: 1 vCPU, 2 GB memory (comparable specs)

### CodeBuild Pricing (us-east-1)

**BUILD_GENERAL1_MEDIUM**: $0.01/minute

| Usage Pattern | Monthly Minutes | Monthly Cost |
|---------------|-----------------|-------------|
| Low (5 runs/day × 10 min) | 1,500 | $15 |
| Medium (20 runs/day × 10 min) | 6,000 | $60 |
| High (50 runs/day × 10 min) | 15,000 | $150 |
| Continuous polling (1 min rate) | 43,200 | $432 |

**Additional costs**: CloudWatch Logs (~$1-2/month)

### ECS Fargate Pricing (us-east-1)

**1 vCPU, 2 GB memory** (always running):
- vCPU: 1 × $0.04048/hour × 730 hours = $29.55/month
- Memory: 2 GB × $0.004445/GB/hour × 730 hours = $6.49/month
- **Total per agent**: ~$36/month

**Additional costs**: CloudWatch Logs (~$1-2/month)

### Spec Comparison

| Resource | CodeBuild MEDIUM | ECS Fargate |
|----------|------------------|-------------|
| vCPU | 2 | 1 |
| Memory | 3 GB | 2 GB |
| Cost/month (24/7) | $432 | $36 |
| Cost/hour | $0.60 | $0.05 |

**Note**: CodeBuild has more resources but only runs on-demand. ECS has less but runs continuously.

### Cost Comparison by Usage

| Scenario | CodeBuild | ECS Fargate | Winner |
|----------|-----------|-------------|--------|
| 1-10 runs/day | $15-30 | $36 | CodeBuild |
| 10-20 runs/day | $30-60 | $36 | Breakeven |
| 20-40 runs/day | $60-120 | $36 | ECS |
| 40+ runs/day | $120+ | $36 | ECS |
| Always available | $432 | $36 | ECS |

### Recommendations

**Use CodeBuild when**:
- Infrequent Terraform runs (<15/day)
- Unpredictable workload patterns
- Need higher compute for complex plans (2 vCPU vs 1)
- Single-run mode with scheduled triggers
- Development/testing environments
- Budget-conscious with low usage

**Use ECS Fargate when**:
- Frequent Terraform runs (>15/day)
- Need immediate job pickup (<1 min latency)
- Predictable, steady workload
- Production environments with SLAs
- Multiple concurrent runs expected
- Willing to trade compute power for availability

**Performance consideration**: CodeBuild MEDIUM has 2x vCPU and 1.5x memory vs ECS default. For equivalent ECS performance, use 2 vCPU/4 GB (~$72/month).

**Hybrid approach**: CodeBuild for dev/staging, ECS for production

**Note**: Prices based on us-east-1. Use [AWS Pricing Calculator](https://calculator.aws) for your region.
