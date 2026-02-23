# Strapi Deployment on AWS ECS Fargate

## Overview
This project deploys a **Strapi application** on **AWS ECS Fargate** using **Terraform** with **CloudWatch logs and metrics**.

---

## Prerequisites
- AWS account
- Terraform installed
- Docker installed (for building Strapi image)
- Existing ECR repository for Strapi image
- IAM role with ECS execution permissions (`ecs-task-execution-role`)

---

## Steps

1. **VPC & Subnets**
   - Use default VPC or create new
   - Ensure public subnet exists

2. **Security Group**
   - Allow port 1337 TCP ingress

3. **CloudWatch Logs**
   - Logs stored in `/ecs/strapi`

4. **ECS Cluster**
   - Cluster for Fargate tasks

5. **Task Definition**
   - CPU 256, Memory 512
   - Port 1337 exposed
   - Logging enabled to CloudWatch

6. **ECS Service**
   - Desired count 1
   - Assign public IP
   - Launch type FARGATE

7. **CloudWatch Metrics & Alarms**
   - Monitor CPU, memory, task count, network
   - Optional alarms for CPU spikes

---

## Deploy Steps

```bash
terraform init
terraform plan
terraform apply -auto-approve
