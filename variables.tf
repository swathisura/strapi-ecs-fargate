variable "aws_region" {
  default = "us-east-1"
}

variable "ecs_cluster_name" {
  default = "strapi-cluster"
}

variable "ecs_task_family" {
  default = "strapi-task"
}

variable "execution_role_arn" {
  description = "Existing ECS task role"
  default     = "arn:aws:iam::811738710312:role/ecs_fargate_taskRole"
}

variable "ecr_image_url" {
  description = "ECR image"
  default     = "811738710312.dkr.ecr.us-east-1.amazonaws.com/swathi-strapi:latest"
}
