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
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"
}

# -------------------------------
# CREATE ECR REPOSITORY
# -------------------------------
resource "aws_ecr_repository" "strapi_repo" {
  name                 = "strapi-app"
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
}

# -------------------------------
# CLOUDWATCH LOG GROUP
# -------------------------------
resource "aws_cloudwatch_log_group" "strapi_log_group" {
  name              = "/ecs/strapi"
  retention_in_days = 14
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

  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "strapi-app"
      image     = "${aws_ecr_repository.strapi_repo.repository_url}:${var.docker_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 1337
          protocol      = "tcp"
        }
      ]

      logConf

