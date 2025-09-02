# VPC principal
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "banana-vpc"
    Environment = "production"
    Project     = "banana"
  }
}

# Internet Gateway pour l'accès internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "banana-igw"
    Environment = "production"
    Project     = "banana"
  }
}

# Subnet public dans AZ a
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "banana-public-a"
    Environment = "production"
    Project     = "banana"
    Type        = "public"
  }
}

# Subnet privé dans AZ a
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name        = "banana-private-a"
    Environment = "production"
    Project     = "banana"
    Type        = "private"
  }
}

# Subnet privé dans AZ b
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-west-3b"

  tags = {
    Name        = "banana-private-b"
    Environment = "production"
    Project     = "banana"
    Type        = "private"
  }
}

# Route table pour le subnet public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "banana-public-rt"
    Environment = "production"
    Project     = "banana"
  }
}

# Association de la route table publique
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway pour les subnets privés
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "banana-nat-eip"
    Environment = "production"
    Project     = "banana"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name        = "banana-nat-gateway"
    Environment = "production"
    Project     = "banana"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route table pour les subnets privés
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "banana-private-rt"
    Environment = "production"
    Project     = "banana"
  }
}

# Association des route tables privées
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
