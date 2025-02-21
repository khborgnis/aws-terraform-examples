locals {
  num_zones = 2
}

resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "demo"
  }
}

resource "aws_subnet" "private" {
  count = local.num_zones

  vpc_id               = aws_vpc.demo.id
  availability_zone_id = data.aws_availability_zones.available.zone_ids[count.index]

  cidr_block = cidrsubnet(aws_vpc.demo.cidr_block, 8, count.index)

  tags = {
    Name = "priv-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_subnet" "public" {
  count = local.num_zones

  vpc_id               = aws_vpc.demo.id
  availability_zone_id = data.aws_availability_zones.available.zone_ids[count.index]

  cidr_block = cidrsubnet(aws_vpc.demo.cidr_block, 8, count.index + 8)

  tags = {
    Name = "pub-${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_internet_gateway" "egress" {
  vpc_id = aws_vpc.demo.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id
}

resource "aws_route_table_association" "public" {
  count          = 2
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route" "egress" {
  route_table_id =  aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.egress.id
}