variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS Cluster Name"
  type        = string
}

variable "ecs_task_family" {
  description = "ECS Task Family"
  type        = string
}

variable "ecr_image_url" {
  description = "Full ECR image URL"
  type        = string
}
