# ECS Cluster
resource "aws_ecs_cluster" "agent" {
  count = var.agent_type == "ecs" ? 1 : 0
  name  = "${local.name_prefix}-cluster"

  tags = local.common_tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "agent" {
  count                    = var.agent_type == "ecs" ? 1 : 0
  family                   = "${local.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = aws_iam_role.ecs_execution[0].arn
  task_role_arn            = aws_iam_role.ecs_task[0].arn

  container_definitions = jsonencode([
    {
      name      = "tfc-agent"
      image     = var.docker_image_name
      essential = true

      environment = [
        {
          name  = "TFC_AGENT_NAME"
          value = "${local.name_prefix}-ecs"
        },
        {
          name  = "TFC_AGENT_LOG_LEVEL"
          value = var.log_level
        }
      ]

      secrets = [
        {
          name      = "TFC_AGENT_TOKEN"
          valueFrom = aws_ssm_parameter.agent_token.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs[0].name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = local.common_tags
}

# ECS Service
resource "aws_ecs_service" "agent" {
  count           = var.agent_type == "ecs" ? 1 : 0
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.agent[0].id
  task_definition = aws_ecs_task_definition.agent[0].arn
  desired_count   = var.agent_pool_size
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.vpc_config.subnets
    security_groups  = concat([aws_security_group.ecs[0].id], var.vpc_config.security_group_ids)
    assign_public_ip = var.ecs_assign_public_ip
  }

  tags = local.common_tags
}

# Security Group for ECS
resource "aws_security_group" "ecs" {
  count       = var.agent_type == "ecs" ? 1 : 0
  name_prefix = "${local.name_prefix}-ecs-"
  description = "Security group for TFC ECS agents"
  vpc_id      = var.vpc_config.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to Terraform Cloud"
  }

  tags = local.common_tags
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  count             = var.agent_type == "ecs" ? 1 : 0
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}
