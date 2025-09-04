# Navigator Application - AWS ECS Deployment

This directory contains the Terraform infrastructure code for deploying the Navigator application on AWS ECS, optimized for free tier usage while following security best practices.

## Architecture Overview

```
Internet → ALB (HTTPS) → ECS Services (HTTP internal)
                        ├── React Frontend (Fargate)
                        ├── Quarkus Backend (Fargate) 
                        └── Keycloak (Fargate)
                        ↓
                  RDS PostgreSQL (Multi-AZ)
```

## Directory Structure

```
AWS/
├── 00-bootstrap/               # Terraform backend and S3 bucket setup
├── 01-network/                 # Network infrastructure (modular approach)
│   ├── 01-vpc/                 # VPC, subnets, VPC endpoints
│   │   ├── main.tf             # VPC, subnets, route tables
│   │   ├── vpc-endpoints.tf    # VPC endpoints for AWS services
│   │   ├── variables.tf        # VPC module variables
│   │   ├── outputs.tf          # VPC outputs (subnet IDs, VPC ID)
│   │   ├── providers.tf        # AWS provider configuration
│   │   ├── versions.tf         # Terraform version requirements
│   │   └── terraform.tfvars    # VPC configuration values
│   └── 02-alb/                 # Application Load Balancer and routing
│       ├── main.tf             # ALB, target groups, listeners
│       ├── security-groups.tf  # Security groups for all services
│       ├── route53.tf          # DNS zones, SSL certificates
│       ├── data.tf             # Remote state references
│       ├── variables.tf        # ALB module variables
│       ├── outputs.tf          # ALB outputs (ARNs, DNS names)
│       ├── providers.tf        # AWS provider configuration
│       ├── versions.tf         # Terraform version requirements
│       └── terraform.tfvars    # ALB configuration values
├── 02-databases/               # RDS PostgreSQL configuration
├── 03-ecr/                     # ECR repositories for container images
├── 04-services/                # ECS cluster and services
│   ├── frontend/               # React frontend service
│   ├── backend/                # Quarkus backend service
│   └── keycloak/               # Keycloak service
├── scripts/                    # Deployment scripts
└── README.md                   # This file
```

## Key Features

### Security Best Practices
- VPC with private subnets for databases
- Security groups with least privilege access
- SSL/TLS termination at ALB
- Internal HTTP communication within VPC
- Secrets Manager for sensitive data
- RDS encryption at rest

### Free Tier Optimization
- Fargate Spot instances for cost savings
- Single RDS db.t3.micro instance (free tier eligible)
- Route 53 hosted zone (free for first hosted zone)
- CloudWatch logs with 7-day retention

### High Availability
- Multi-AZ deployment
- Application Load Balancer with health checks
- Auto Scaling for ECS services
- RDS Multi-AZ for database

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **Docker** for building container images
4. **Domain names** configured in Route 53

## Quick Start

1. **Configure AWS credentials:**
   ```bash
   aws configure
   ```

2. **Copy and customize variables:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Deploy infrastructure:**
   ```bash
   ./scripts/on.sh
   ```

## Infrastructure Deployment

### Modular Network Infrastructure (01-network)

The network infrastructure is split into two independent modules that must be deployed in order:

#### 1. VPC Module (01-vpc)
Contains the base networking infrastructure:
- VPC with DNS hostnames and support enabled
- Public subnets (for ALB), Private subnets (for ECS tasks), Database subnets (for RDS)
- Internet Gateway, Route Tables, and Database Subnet Group
- VPC Endpoints (ECR, CloudWatch Logs, Secrets Manager, S3, ECS)

```bash
cd AWS/01-network/01-vpc/

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply deployment
terraform apply
```

#### 2. ALB Module (02-alb)
Contains application-level resources that depend on VPC:
- Application Load Balancer with HTTPS listeners and Target Groups
- Security Groups (ALB, ECS, Database, EFS)
- Route53 Hosted Zones (.fr and .com) and ACM SSL Certificate
- DNS records pointing to ALB

```bash
cd AWS/01-network/02-alb/

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply deployment
terraform apply
```

**Important**: The ALB module reads VPC outputs via Terraform remote state, so VPC must be deployed first.

**State Files**:
- VPC: `s3://navigator-state/terraform/vpc.tfstate`
- ALB: `s3://navigator-state/terraform/alb.tfstate`

### Manual Deployment Steps (Legacy)

#### 1. Infrastructure Deployment

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply deployment
terraform apply
```

### 2. Build and Push Docker Images

```bash
# Get ECR repository URLs
FRONTEND_REPO=$(terraform output -raw frontend_ecr_repository_url)
BACKEND_REPO=$(terraform output -raw backend_ecr_repository_url)
KEYCLOAK_REPO=$(terraform output -raw keycloak_ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $FRONTEND_REPO

# Build and push images
docker build -t frontend:latest ../../frontend/
docker tag frontend:latest $FRONTEND_REPO:latest
docker push $FRONTEND_REPO:latest

# Repeat for backend and keycloak...
```

### 3. Update ECS Services

```bash
CLUSTER_NAME=$(terraform output -raw ecs_cluster_arn | cut -d'/' -f2)

aws ecs update-service --cluster $CLUSTER_NAME --service navigator-prod-frontend-service --force-new-deployment
aws ecs update-service --cluster $CLUSTER_NAME --service navigator-prod-backend-service --force-new-deployment
aws ecs update-service --cluster $CLUSTER_NAME --service navigator-prod-keycloak-service --force-new-deployment
```

## Configuration

### Domain Configuration

The application supports multiple domains:
- Frontend: `app.one-navigator.fr`, `app.one-navigator.com`
- Keycloak: `auth.one-navigator.fr`, `auth.one-navigator.com`

### Environment Variables

#### React Frontend
- `REACT_APP_API_URL`: Backend API URL
- `REACT_APP_AUTH_URL`: Keycloak URL
- `REACT_APP_AUTH_REALM`: Keycloak realm name
- `REACT_APP_AUTH_CLIENT_ID`: Keycloak client ID

#### Quarkus Backend
- Database connection via Secrets Manager
- Keycloak configuration via Secrets Manager
- Health check endpoint: `/q/health`

#### Keycloak
- Database connection via Secrets Manager
- Admin credentials via Secrets Manager
- Health check endpoint: `/health/ready`

## Monitoring and Logging

- **CloudWatch Logs**: All services log to CloudWatch
- **Health Checks**: ALB health checks for all services
- **Auto Scaling**: CPU-based auto scaling for all services
- **RDS Monitoring**: Enhanced monitoring enabled

## Security Considerations

1. **Network Security**:
    - Private subnets for ECS tasks
    - Database in isolated subnets
    - Security groups with minimal access

2. **Data Security**:
    - RDS encryption at rest
    - Secrets Manager for credentials
    - SSL/TLS for external communication

3. **Access Control**:
    - IAM roles with least privilege
    - ECR image scanning enabled
    - VPC endpoints for AWS services

## Cost Optimization

### Free Tier Usage
- RDS db.t3.micro (750 hours/month free)
- Route 53 hosted zone (first zone free)
- CloudWatch logs (5GB free)
- ECR (500MB free)

### Cost-Saving Measures
- Fargate Spot instances
- 7-day log retention
- Single RDS instance
- Minimal resource allocation

## Troubleshooting

### Common Issues

1. **Certificate Validation**:
    - Ensure DNS records are properly configured
    - Wait for certificate validation to complete

2. **Service Health Checks**:
    - Check CloudWatch logs for service issues
    - Verify security group rules
    - Ensure proper environment variables

3. **Database Connection**:
    - Verify Secrets Manager configuration
    - Check security group rules
    - Ensure database is accessible from ECS tasks

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster navigator-prod-cluster --services navigator-prod-frontend-service

# View CloudWatch logs
aws logs tail /ecs/navigator-prod-frontend --follow

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## Cleanup

To destroy the infrastructure:

```bash
cd terraform
terraform destroy
```

**Warning**: This will permanently delete all resources and data.

## Support

For issues and questions:
1. Check CloudWatch logs
2. Review Terraform state
3. Verify AWS service limits
4. Check security group configurations