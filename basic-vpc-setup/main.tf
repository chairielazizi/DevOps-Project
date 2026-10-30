terraform {
  required_version = ">=1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment  = "Production"
      EngineeredBy = "Terraform"
      Project      = "DevOps-Basic-VPC"
    }
  }
}

# Dynamic number availability_zone
data "aws_availability_zones" "available" {
  state = "available"
}

#1. Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "basic-vpc-setup-vpc"
  }
}

#2. Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "basic-vpc-setup-igw"
  }
}

#3. Subnets configuration

# Create public subnets
resource "aws_subnet" "public" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id
  #   cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  # cidr_block              = "10.0.${count.index + 1}.0/24"
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "basic-vpc-setup-public-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "Public"
  }
}

# Create application subnets
resource "aws_subnet" "application" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id
  # cidr_block              = "10.0.${count.index + 4}.0/24"
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 4)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "basic-vpc-setup-application-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "Application"
  }
}

# Create database subnets
resource "aws_subnet" "database" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id
  # cidr_block              = "10.0.${count.index + 7}.0/24"
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 7)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "basic-vpc-setup-database-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "Database"
  }
}

# Create management subnets
resource "aws_subnet" "management" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id
  # cidr_block              = "10.0.${count.index + 10}.0/24"
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "basic-vpc-setup-management-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "Management"
  }
}

# Create platform subnets
resource "aws_subnet" "platform" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id
  # cidr_block              = "10.0.${count.index + 13}.0/24"
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 13)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "basic-vpc-setup-platform-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "Platform"
  }
}

#4. Elastic IP and NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "basic-vpc-setup-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  #   depends_on = [ aws_internet_gateway.igw ]
  tags = {
    Name = "basic-vpc-setup-nat-gateway"
  }
}

#5. Route tables and routes association

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "basic-vpc-setup-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "basic-vpc-setup-private-route-table"
  }
}

resource "aws_route_table_association" "application" {
  count          = var.az_count
  subnet_id      = aws_subnet.application[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "management" {
  count          = var.az_count
  subnet_id      = aws_subnet.management[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "platform" {
  count          = var.az_count
  subnet_id      = aws_subnet.platform[count.index].id
  route_table_id = aws_route_table.private.id
}

# Create database route table (isolated, no internet access)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "basic-vpc-setup-database-route-table"
  }
}

resource "aws_route_table_association" "database" {
  count          = var.az_count
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}


#6. Network ACLs for database subnets (optional, for additional security)
resource "aws_network_acl" "database" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [for subnet in aws_subnet.database : subnet.id]

  # Inbound rules
  # Dynamically generates ingress block for each application subnets
  dynamic "ingress" {
    for_each = aws_subnet.application
    content {
      rule_no    = 100 + (ingress.key * 10) #100, 110, 120... automatically
      protocol   = "tcp"
      action     = "allow"
      from_port  = 3306 # MySQL port
      to_port    = 3306
      cidr_block = ingress.value.cidr_block # Reads live subnet CIDR directly
    }
  }

  # Outbound rules
  # Dynamically generates ingress block for each application subnets
  dynamic "egress" {
    for_each = aws_subnet.application
    content {
      rule_no = 100 + (egress.key * 10) #100, 110, 120... automatically
      # protocol = "-1" # All protocols
      protocol   = "tcp"
      action     = "allow"
      from_port  = 1024
      to_port    = 65535
      cidr_block = egress.value.cidr_block # Reads live subnet CIDR directly
    }
  }

  tags = {
    Name = "basic-vpc-setup-database-nacl"
  }
}

#7. VPC endpoint for S3 (optional, for private access to S3 without internet)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private.id,
    aws_route_table.database.id
  ]
  tags = {
    Name = "basic-vpc-setup-s3-endpoint"
  }
}
