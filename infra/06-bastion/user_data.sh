#!/bin/bash

# Update system packages
apt update -y
apt upgrade -y

# Install useful tools for bastion host
apt install -y \
    htop \
    vim \
    git \
    curl \
    wget \
    unzip \
    jq \
    awscli \
    postgresql-client

# Ensure SSM Agent is installed and running
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

# Configure AWS CLI region (will be set by user)
mkdir -p /home/ubuntu/.aws

# Create a welcome message
cat > /etc/motd << EOF
========================================
Bastion Host - ${project_name}
========================================
This is a bastion host for secure access to your VPC resources.

Useful commands:
- aws configure (to set up AWS CLI)
- aws sts get-caller-identity (to check AWS identity)
- htop (system monitoring)
- git (version control)

Remember to:
1. Configure AWS CLI with your credentials
2. Use this host to access private resources in your VPC
3. Keep this instance updated and secure

========================================
EOF

# Set proper permissions
chown ubuntu:ubuntu /home/ubuntu/.aws
chmod 700 /home/ubuntu/.aws

# Log the completion
echo "$(date): Bastion host setup completed" >> /var/log/bastion-setup.log