resource "aws_vpc" "hotstar_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "hotstar-vpc"
  }
}

# -----------------------------
# Public Subnets
# -----------------------------
resource "aws_subnet" "public_subnet" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.hotstar_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# -----------------------------
# Private Subnets
# (Keeping for future use)
# -----------------------------
resource "aws_subnet" "private_subnet" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.hotstar_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                        = "private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# -----------------------------
# Internet Gateway
# -----------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hotstar_vpc.id

  tags = {
    Name = "hotstar-igw"
  }
}

# =====================================================
# NAT Gateway (Disabled for Learning)
# Uncomment these resources when using private subnets.
# =====================================================

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "hotstar-nat-gateway"
  }
}

# -----------------------------
# Public Route Table
# -----------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.hotstar_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# =====================================================
# Private Route Table (Disabled)
# Uncomment when NAT Gateway is enabled.
# =====================================================

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.hotstar_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# -----------------------------
# Public Route Table Association
# -----------------------------
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public_subnet)

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# =====================================================
# Private Route Table Association (Disabled)
# Uncomment when NAT Gateway is enabled.
# =====================================================

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private_subnet)

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}