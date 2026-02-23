provider "aws" {
  region = var.aws_region
}

# -------------------------------
# DEFAULT VPC
# -------------------------------
data "aws_vpc" "default" {
  default = true
}

# -------------------------------
# DEFAULT SUBNETS
# -------------------------------
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -------------------------------
# EXISTING SECURITY GROUP (shared account)
# -------------------------------
data "aws_security_group" "strapi_sg" {
  name   = "strapi-sg"
  vpc_id = data.aws_vpc.default.id
}

# -------------------------------
# ECS CLUSTER
# -------------------------------
resource "aws_ecs_cluster" "strapi_cluster" {
  name = var.ecs_cluster_name
}

# -------------------------------
# EXISTING CLOUDWATCH LOG GROUP
# -------------------------------
locals {
  log_group_name = "/ecs/strapi"
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

  # Use existing role (shared account)
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
          "awslogs-group"         = local.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
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
    subnets         = data.aws_subnets.default.ids
    security_groups = [data.aws_security_group.strapi_sg.id]
    assign_public_ip = true
  }
}
