resource "aws_vpc" "main" {
   cidr_block = var.vpc_cidr_block 
}

resource "aws_subnet" "first" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1a"
  cidr_block        = cidrsubnet(var.vpc_cidr_block, var.vpc_net_host_bits, 0)
}

resource "aws_subnet" "second" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1b"
  cidr_block        = cidrsubnet(var.vpc_cidr_block, var.vpc_net_host_bits, 1)
}