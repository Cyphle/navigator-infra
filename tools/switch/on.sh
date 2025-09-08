#!/bin/bash

# Navigator Application Deployment Script
# This script deploys the infrastructure and applications to AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_requirements() {
    print_status "Checking requirements..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    print_status "All requirements are met."
}

# Check AWS credentials
check_aws_credentials() {
    print_status "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_status "AWS credentials are configured."
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    cd terraform
    terraform init
    print_status "Terraform initialized."
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_status "Terraform plan completed."
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    print_status "Terraform deployment completed."
}

# Build and push Docker images
build_and_push_images() {
    print_status "Building and pushing Docker images..."
    
    # Get ECR repository URLs from Terraform output
    FRONTEND_REPO=$(terraform output -raw frontend_ecr_repository_url)
    BACKEND_REPO=$(terraform output -raw backend_ecr_repository_url)
    KEYCLOAK_REPO=$(terraform output -raw keycloak_ecr_repository_url)
    
    # Login to ECR
    aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin $FRONTEND_REPO
    
    # Build and push frontend image
    print_status "Building frontend image..."
    docker build -t frontend:latest ../../frontend/
    docker tag frontend:latest $FRONTEND_REPO:latest
    docker push $FRONTEND_REPO:latest
    
    # Build and push backend image
    print_status "Building backend image..."
    docker build -t backend:latest ../../backend/
    docker tag backend:latest $BACKEND_REPO:latest
    docker push $BACKEND_REPO:latest
    
    # Build and push keycloak image
    print_status "Building keycloak image..."
    docker build -t keycloak:latest ../../keycloak/
    docker tag keycloak:latest $KEYCLOAK_REPO:latest
    docker push $KEYCLOAK_REPO:latest
    
    print_status "All images built and pushed successfully."
}

# Update ECS services
update_ecs_services() {
    print_status "Updating ECS services..."
    
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_arn | cut -d'/' -f2)
    
    # Force new deployment for all services
    aws ecs update-service --cluster $CLUSTER_NAME --service navigator-prod-frontend-service --force-new-deployment
    aws ecs update-service --cluster $CLUSTER_NAME --service navigator-prod-backend-service --force-new-deployment
    aws ecs update-service --cluster $CLUSTER_NAME --service navigator-prod-keycloak-service --force-new-deployment
    
    print_status "ECS services updated."
}

# Wait for services to be stable
wait_for_services() {
    print_status "Waiting for services to be stable..."
    
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_arn | cut -d'/' -f2)
    
    aws ecs wait services-stable --cluster $CLUSTER_NAME --services navigator-prod-frontend-service
    aws ecs wait services-stable --cluster $CLUSTER_NAME --services navigator-prod-backend-service
    aws ecs wait services-stable --cluster $CLUSTER_NAME --services navigator-prod-keycloak-service
    
    print_status "All services are stable."
}

# Main deployment function
main() {
    print_status "Starting Navigator application deployment..."
    
    check_requirements
    check_aws_credentials
    init_terraform
    plan_terraform
    
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled."
        exit 0
    fi
    
    apply_terraform
    build_and_push_images
    update_ecs_services
    wait_for_services
    
    print_status "Deployment completed successfully!"
    print_status "Application URLs:"
    print_status "Frontend: https://app.one-navigator.fr"
    print_status "Keycloak: https://auth.one-navigator.fr"
}

# Run main function
main "$@"