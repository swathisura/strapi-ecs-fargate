provider "aws" {
  region = var.aws_region
}

# -------------------------------
# USE EXISTING DEFAULT VPC
# -------------------------------
data "aws_vpc" "default" {
  default = true
}

# -------------------------------
# USE EXISTING SUBNETS
# -------------------------------
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -------------------------------
# USE EXISTING SECURITY GROUP
# -------------------------------
data "aws_security_group" "strapi_sg" {
  name   = "strapi-sg"
  vpc_id = data.aws_vpc.default.id
}

# -------------------------------
# ECS CLUSTER (safe to create)
# -------------------------------
resource "aws_ecs_cluster" "strapi_cluster" {
  name = var.ecs_cluster_name
}

# -------------------------------
# CLOUDWATCH LOG GROUP
# (Ignore errors if already exists)
# -------------------------------
resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/strapi"
  retention_in_days = 7

  lifecycle {
    ignore_changes = all
  }
}

# -------------------------------
# ECS TASK DEFINITION
# -------------------------------
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = var.ecs_task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  # IMPORTANT: use existing execution role
  execution_role_arn = var.ecs_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "strapi-app"
      image     = var.ecr_image_url
      essential = true

      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/strapi"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# -------------------------------
# ECS SERVICE
# -------------------------------
resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [data.aws_security_group.strapi_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_cloudwatch_log_group.strapi_logs]
}
