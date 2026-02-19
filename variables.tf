variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ecs_cluster_name" {
  type    = string
  default = "strapi-cluster"
}

variable "ecs_task_family" {
  type    = string
  default = "strapi-task"
}

variable "docker_image_tag" {
  type    = string
  default = "latest"
}
