provider "aws" {
  region = var.aws_region
}

# -------------------------------
# EXISTING DEFAULT VPC
# -------------------------------
data "aws_vpc" "default" {
  default = true
}

# -------------------------------
# EXISTING SUBNETS (from default VPC)
# -------------------------------
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -------------------------------
# CREATE SUBNET IF NONE EXIST
# -------------------------------
resource "aws_subnet" "strapi_subnet" {
  count                   = length(data.aws_subnets.default.ids) == 0 ? 1 : 0
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 8, 1)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

# -------------------------------
# FINAL SUBNET IDS TO USE
# -------------------------------
locals {
  subnet_ids = length(data.aws_subnets.default.ids) > 0 ? data.aws_subnets.default.ids : [aws_subnet.strapi_subnet[0].id]
}

# -------------------------------
# EXISTING SECURITY GROUP
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
# ECS TASK EXECUTION ROLE
# -------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------------------------------
# ECR REPOSITORY
# -------------------------------
resource "aws_ecr_repository" "strapi_repo" {
  name                 = "strapi-ecs"
  image_tag_mutability = "MUTABLE"
  encryption_configuration {
    encryption_type = "AES256"
  }
}

# -------------------------------
# CLOUDWATCH LOG GROUP
# -------------------------------
resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/strapi"
  retention_in_days = 7
}

# -------------------------------
# ECS TASK DEFINITION (FARGATE)
# -------------------------------
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = var.ecs_task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "strapi-app"
      image     = "${aws_ecr_repository.strapi_repo.repository_url}:latest"
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
          "awslogs-group"         = "/ecs/strapi"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# -------------------------------
# ECS SERVICE (FARGATE)
# -------------------------------
resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = local.subnet_ids
    security_groups = [data.aws_security_group.strapi_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_cloudwatch_log_group.strapi_logs]
}
