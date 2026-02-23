provider "aws" {
  region = "us-east-1"
}

# ----------------------------
# Existing Infrastructure
# ----------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Use EXISTING security group (replace name if needed)
data "aws_security_group" "existing" {
  name   = "strapi-sg"
  vpc_id = data.aws_vpc.default.id
}

# Use EXISTING IAM role (replace with real role name)
data "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
}

# ----------------------------
# ECS Cluster
# ----------------------------
resource "aws_ecs_cluster" "strapi_cluster" {
  name = "strapi-cluster"
}

# ----------------------------
# CloudWatch Logs (skip creation if exists)
# ----------------------------
resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/strapi"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = true
  }
}

# ----------------------------
# Task Definition
# ----------------------------
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = data.aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "strapi"
      image = "YOUR_ECR_IMAGE_URI"
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
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ----------------------------
# ECS Service
# ----------------------------
resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [data.aws_security_group.existing.id]
    assign_public_ip = true
  }
}
