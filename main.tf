resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"
  tags {
    Name = "${var.name} ${var.env} VPC"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "${var.name} ${var.env} GW"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_subnet" "public_subnets" {
  count                   = "${var.num_azs}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${cidrsubnet(var.public_subnet_tier_cidr, 2, count.index)}"
  map_public_ip_on_launch = true
  availability_zone       = "${element(var.azs, (count.index % var.num_azs))}"
  tags {
    Name = "${var.name} ${var.env} AZ ${(count.index % var.num_azs) + 1}"
  }
}

# NAT Gateway EIP
resource "aws_eip" "nat_eip" {
  vpc = true
  count = "${var.nat_gw ? var.num_azs : 0}"
}

# NAT Gateway 
resource "aws_nat_gateway" "nat_gw" {
  count = "${var.nat_gw ? var.num_azs : 0}"
  subnet_id               = "${element(aws_subnet.public_subnets.*.id, count.index)}"
  allocation_id           = "${element(aws_eip.nat_eip.*.id, count.index)}"
  depends_on              = ["aws_internet_gateway.gw"]
}

resource "aws_route_table" "private_route_tables" {
  vpc_id = "${aws_vpc.vpc.id}"
  count = "${var.nat_gw ? var.num_azs : 0}"
  tags {
    Name = "${var.name} ${var.env} Private Route Table ${count.index}"
  }
}

resource aws_route "private_ipv4_nat_route" {
  count = "${var.nat_gw ? var.num_azs : 0}"
  route_table_id            = "${element(aws_route_table.private_route_tables.*.id, count.index)}"
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = "${element(aws_nat_gateway.nat_gw.*.id, count.index)}"  
}


resource aws_route "private_ipv6_nat_route" {
  count = "${var.nat_gw ? var.num_azs : 0}"
  route_table_id            = "${element(aws_route_table.private_route_tables.*.id, count.index)}"
  destination_ipv6_cidr_block      = "::/0"
  nat_gateway_id = "${element(aws_nat_gateway.nat_gw.*.id, count.index)}"  
}

output "vpc_id" { 
    value = "${aws_vpc.vpc.id}" 
}

output "public_nat_eips" { 
    value = "${aws_eip.nat_eip.*.public_ip}" 
}
output "private_nat_eips" { 
    value = "${aws_eip.nat_eip.*.private_ip}" 
}
output "nat_ids" { 
    value = "${aws_eip.nat_eip.*.id}" 
}

output "private_route_tables" {
    value = "${aws_route_table.private_route_tables.*.id}"
}

output "public_route_table" {
    value = "${aws_vpc.vpc.*.main_route_table_id}"
}

output "public_subnets" {
  value = "${aws_subnet.public_subnets.*.id}"
}

output "azs" {
    value = "${var.azs}"
}

