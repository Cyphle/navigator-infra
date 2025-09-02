# Récupération des informations du VPC
data "aws_vpc" "main" {
  tags = {
    Name = "banana-vpc"
  }
}

# Récupération des subnets privés
data "aws_subnet" "private_subnets" {
  count = 2
  tags = {
    Name = count.index == 0 ? "banana-private-a" : "banana-private-b"
  }
}

# Récupération du security group EKS
data "aws_security_group" "eks_cluster" {
  tags = {
    Name = "banana-eks-cluster-sg"
  }
}
