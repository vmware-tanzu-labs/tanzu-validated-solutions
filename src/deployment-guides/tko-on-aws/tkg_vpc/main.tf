module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.vpc_subnet
  networks = [
    {
      name     = "az1_private"
      new_bits = 8
    },
    {
      name     = "az2_private"
      new_bits = 8
    },
    {
      name     = "az3_private"
      new_bits = 8
    },
    {
      name     = "az1_public"
      new_bits = 8
    },
    {
      name     = "az2_public"
      new_bits = 8
    },
    {
      name     = "az3_public"
      new_bits = 8
    },
    {
      name     = "az3_jumpnet"
      new_bits = 8
    },
  ]
}


# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_subnet
  tags = {
    Name = "${var.name}"
  }

}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "priv_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = module.subnet_addrs.network_cidr_blocks.az1_private
  availability_zone = var.azs[0]
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "true",
    "kubernetes.io/role/internal-elb"           = "1",
    Name                                        = "priv-a"
  }
}
resource "aws_subnet" "priv_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = module.subnet_addrs.network_cidr_blocks.az2_private
  availability_zone = var.azs[1]
  tags              = { "kubernetes.io/cluster/${var.cluster_name}" = "true", "kubernetes.io/role/internal-elb" = "1", Name = "priv-b" }
}
resource "aws_subnet" "priv_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = module.subnet_addrs.network_cidr_blocks.az3_private
  availability_zone = var.azs[2]
  tags              = { "kubernetes.io/cluster/${var.cluster_name}" = "true", "kubernetes.io/role/internal-elb" = "1", Name = "priv-c" }
}
resource "aws_subnet" "pub_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = module.subnet_addrs.network_cidr_blocks.az1_public
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true
  tags                    = { "kubernetes.io/cluster/${var.cluster_name}" = "true", "kubernetes.io/role/elb" = "1", Name = "pub-a" }
}
resource "aws_subnet" "pub_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = module.subnet_addrs.network_cidr_blocks.az2_public
  availability_zone       = var.azs[1]
  map_public_ip_on_launch = true
  tags                    = { "kubernetes.io/cluster/${var.cluster_name}" = "true", "kubernetes.io/role/elb" = "1", Name = "pub-b" }
}
resource "aws_subnet" "pub_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = module.subnet_addrs.network_cidr_blocks.az3_public
  availability_zone       = var.azs[2]
  map_public_ip_on_launch = true
  tags                    = { "kubernetes.io/cluster/${var.cluster_name}" = "true", "kubernetes.io/role/elb" = "1", Name = "pub-c" }
}
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.pub_a.id
  depends_on    = [aws_internet_gateway.gw]
}



resource "aws_route_table_association" "pub-1a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.r.id
}

resource "aws_route_table_association" "pub-1b" {
  subnet_id      = aws_subnet.pub_b.id
  route_table_id = aws_route_table.r.id
}

resource "aws_route_table_association" "pub-1c" {
  subnet_id      = aws_subnet.pub_c.id
  route_table_id = aws_route_table.r.id
}

resource "aws_route_table" "p" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }
  route {
    cidr_block         = var.transit_block
    transit_gateway_id = var.transit_gw
  }

  tags = {
    Name = "${var.name}-nat"
  }
}


resource "aws_ec2_transit_gateway_vpc_attachment" "gw_attach" {
  subnet_ids         = [aws_subnet.priv_a.id, aws_subnet.priv_b.id, aws_subnet.priv_c.id]
  transit_gateway_id = var.transit_gw
  vpc_id             = aws_vpc.main.id
}


resource "aws_route_table_association" "priv-1a" {
  subnet_id      = aws_subnet.priv_a.id
  route_table_id = aws_route_table.p.id
}

resource "aws_route_table_association" "priv-1b" {
  subnet_id      = aws_subnet.priv_b.id
  route_table_id = aws_route_table.p.id
}

resource "aws_route_table_association" "priv-1c" {
  subnet_id      = aws_subnet.priv_c.id
  route_table_id = aws_route_table.p.id
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    cidr_block         = var.transit_block
    transit_gateway_id = var.transit_gw
  }

  tags = {
    Name = "${var.name}-igw"
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = [aws_subnet.priv_a.id, aws_subnet.priv_b.id, aws_subnet.priv_c.id]
}
output "priv_subnet_a" {
  value = aws_subnet.priv_a.id
}
output "priv_subnet_b" {
  value = aws_subnet.priv_b.id
}
output "priv_subnet_c" {
  value = aws_subnet.priv_c.id
}
output "pub_subnet_a" {
  value = aws_subnet.pub_a.id
}
output "pub_subnet_b" {
  value = aws_subnet.pub_b.id
}
output "pub_subnet_c" {
  value = aws_subnet.pub_c.id
}

output "az1" {
  value = var.azs[0]
}
output "az2" {
  value = var.azs[1]
}
output "az3" {
  value = var.azs[2]
}