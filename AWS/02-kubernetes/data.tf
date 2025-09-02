# Récupération des informations du VPC
data "aws_vpc" "main" {
  tags = {
    Name = "banana-vpc"
  }
}

# Récupération des subnets publics
data "aws_subnet" "public_subnets" {
  count = 1
  tags = {
    Name = "banana-public-a"
  }
}

# Récupération des subnets privés
data "aws_subnet" "private_subnets" {
  count = 2
  tags = {
    Name = count.index == 0 ? "banana-private-a" : "banana-private-b"
  }
}
