# Enterprise Node.js Deployment via AWS ECS Fargate & Terraform

## Overview
This repository contains a production-grade, highly available infrastructure deployment for a containerized Node.js application. The architecture is provisioned entirely via modular Infrastructure as Code (Terraform), managed by a secure CI/CD pipeline (GitHub Actions with OIDC), and orchestrated using serverless compute (AWS ECS Fargate).

## Architecture
![Architecture Diagram](./architecture.jpg)

### 1. Network Topology (AWS VPC)
The application resides in a custom Virtual Private Cloud (VPC) spanning two Availability Zones (`us-east-1a`, `us-east-1b`) to ensure high availability.
* **VPC CIDR:** `10.0.0.0/16`
* **Public Subnets:** `10.0.1.0/24` & `10.0.2.0/24`. These host the Application Load Balancer (ALB), Internet Gateway (IGW), and a NAT Gateway.
* **Private Subnets:** `10.0.10.0/24` & `10.0.20.0/24`. These securely host the ECS Fargate tasks. Outbound internet access (e.g., for pulling container images) is routed strictly through the NAT Gateway. 

### 2. Compute & Orchestration (AWS ECS Fargate)
The application runs as a Docker container managed by Amazon Elastic Container Service (ECS) using the Fargate launch type, completely abstracting the underlying EC2 instances.
* **Container Specifications:** 0.25 vCPU, 0.5 GB Memory.
* **Application Port:** The Node.js application listens on **Port 3000**.
* **Traffic Routing:** The ALB listens on Port 80 and securely forwards traffic to the Target Group on Port 3000.
* **Health Checks:** The ALB actively monitors container health via the `/health` endpoint. Unhealthy containers are automatically terminated and replaced by ECS.

### 3. CI/CD Pipeline (GitHub Actions)
Deployments are fully automated, integrating automated testing and zero-downtime rolling updates.
* **OIDC Authentication:** GitHub Actions authenticates with AWS via OpenID Connect (OIDC). No long-lived permanent credentials or IAM access keys are stored in GitHub Secrets.
* **Automated Testing:** The pipeline leverages a multi-stage Dockerfile. Stage 2 natively executes the Jest test suite. The image is only pushed to the Elastic Container Registry (ECR) if all tests pass.
* **Rolling Deployment:** Upon a successful push to the `main` branch, the pipeline forces ECS to pull the `latest` image tag and perform a rolling update, ensuring zero application downtime.

### 4. Observability (AWS CloudWatch)
Comprehensive monitoring is baked into the infrastructure.
* **Centralized Logging:** `stdout` and `stderr` from the Node.js containers are streamed directly to a dedicated CloudWatch Log Group via the `awslogs` driver.
* **Dashboard:** A custom CloudWatch Dashboard visualizes real-time CPU and Memory utilization across the ECS cluster.
* **Alarms:** A CloudWatch Metric Alarm is configured to trigger if the average CPU utilization exceeds 80% over two consecutive evaluation periods.

## Design Decisions & Best Practices
* **Multi-Stage Docker Build:** The container image is optimized for production by stripping development dependencies (reducing attack surface and image size), stepping down to a non-root `node` user for security, and implementing `tini` as PID 1 to gracefully handle SIGTERM signals from ECS.
* **Terraform Modularity & State Management:** Infrastructure is divided into distinct, logical modules (`networking`, `alb`, `ecs`, `monitoring`). The Terraform state is stored remotely in an S3 bucket with DynamoDB state locking enabled to prevent concurrent state corruption during automated pipeline runs.
* **Least Privilege IAM:** The ECS Task Execution Role is strictly scoped to only allow actions necessary for operation (pulling from ECR, writing to CloudWatch).

## Assumptions & Future Improvements
* **Assumptions:** For the scope of this challenge, the application only requires HTTP (Port 80) ingress.
* **TLS/HTTPS:** In a true production environment, an ACM (AWS Certificate Manager) SSL/TLS certificate would be provisioned and attached to an HTTPS (Port 443) listener on the ALB.
* **WAF Integration:** An AWS Web Application Firewall (WAF) should be attached to the ALB to protect against common web exploits (e.g., SQLi, XSS) and implement rate limiting.
* **Secrets Management:** Environment variables are not currently utilized. Future iterations would inject sensitive configuration data securely via AWS Systems Manager Parameter Store or AWS Secrets Manager.

## Manual Disaster Recovery Deployment
Should the CI/CD pipeline become compromised or unavailable, the infrastructure can be deployed manually from a local terminal:

1. Initialize Terraform backend:
   ```bash
   cd terraform
   terraform init

Application choice. I implemented the deployable artifact as a containerized JSON API rather than a full-stack web application. The challenge brief frames the application as a vehicle for evaluating the DevOps stack around it, and a stateless HTTP service is the architecture that most directly exercises the requirements: containerization, health checks for load balancer integration, structured logging to CloudWatch, horizontal scalability through ECS task counts, and rolling deployment without service disruption. A user-facing frontend with HTML/CSS/JavaScript would have added domain complexity (asset bundling, CDN hosting patterns, browser-side routing) without testing any additional DevOps capability beyond what the API already exercises.
