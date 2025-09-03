# Récupération des informations du VPC
data "aws_vpc" "main" {
  tags = {
    Name = "navigator-vpc"
  }
}

# Récupération des subnets publics
data "aws_subnet" "public_subnets" {
  count = 1
  tags = {
    Name = "navigator-public-a"
  }
}

# Récupération des subnets privés
data "aws_subnet" "private_subnets" {
  count = 2
  tags = {
    Name = count.index == 0 ? "navigator-private-a" : "navigator-private-b"
  }
}
