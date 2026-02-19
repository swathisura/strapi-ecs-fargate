########################################################
# Provider
########################################################
provider "aws" {
  region = var.aws_region
}

########################################################
# Step 1: VPC & Subnets
########################################################

# Use existing default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create a subnet if none exist
resource "aws_subnet" "strapi_subnet" {
  count                   = length(data.aws_subnets.default.ids) == 0 ? 1 : 0
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 8, 1)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

# Final subnet IDs to use in ECS service
locals {
  subnet_ids = length(data.aws_subnets.default.ids) > 0 ? data.aws_subnets.default.ids : [aws_subnet.strapi_subnet[0].id]
}

########################################################
# Step 2: Security Group
########################################################

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow HTTP traffic to Strapi"
  vpc_id      = data.aws_vpc.default.id

  # Ingress - allow HTTP on port 1337
  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress - allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
