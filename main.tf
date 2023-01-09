resource "aws_vpc" "vpc" {
  cidr_block           = var.sanjosnet
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}
resource "aws_subnet" "public" {
  count                   = local.subnets - 1
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.sanjosnet, 2, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-${var.environment}-public${count.index + 1}"
  }
}
resource "aws_subnet" "private" {
  count                   = local.subnets - 2
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.sanjosnet, 2, "${count.index + 2}")
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-${var.environment}-private${count.index + 1}"
  }
}
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0
  vpc = true
  tags = {
    Name = "${var.project}-${var.environment}-natgw"
  }
}
resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat.0.id
  subnet_id     = aws_subnet.public[1].id
  tags = {
    Name = "${var.project}-${var.environment}"
  }
  depends_on = [aws_internet_gateway.igw]
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-public"
  }
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "${var.project}-${var.environment}-private"
  }
}
resource "aws_route" "enable_nat" {
  count = var.enable_nat_gateway ? 1 : 0
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat.0.id
  depends_on                = [ aws_route_table.private]
}

resource "aws_route_table_association" "public" {
  count          = local.subnets - 1
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  count          = local.subnets - 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
