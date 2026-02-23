variable "aws_region" {
  default = "us-east-1"
}

variable "ecs_cluster_name" {
  default = "strapi-cluster"
}

variable "ecs_task_family" {
  default = "strapi-task"
}

# EXISTING IAM ROLE IN YOUR ACCOUNT
variable "ecs_execution_role_arn" {
  default = "arn:aws:iam::811738710312:role/ecs_fargate_taskRole"
}

# YOUR ECR IMAGE
variable "ecr_image_url" {
  default = "811738710312.dkr.ecr.us-east-1.amazonaws.com/swathi-strapi:latest"
}
