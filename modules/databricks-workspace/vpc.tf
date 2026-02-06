resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, {
    Name = "${var.prefix}-vpc-${var.suffix}"
  })
}

resource "aws_subnet" "db_private_subnet" {
  vpc_id                  = aws_vpc.this.id
  count                   = length(local.db_private_subnets_cidr)
  cidr_block              = element(local.db_private_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = false
  tags = merge(var.tags, {
    Name = "${var.prefix}-db-private-${element(local.availability_zones, count.index)}-${var.suffix}"
  })
}

resource "aws_route_table" "db_private_rt" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.prefix}-db-private-rt-${var.suffix}"
  })
}

resource "aws_main_route_table_association" "worker-default-rt-assoc" {
  vpc_id         = aws_vpc.this.id
  route_table_id = aws_route_table.db_private_rt.id
}

resource "aws_security_group" "default_sg" {
  name        = "${var.prefix}-default-sg-${var.suffix}"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = aws_vpc.this.id
  depends_on  = [aws_vpc.this]

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    self      = true
  }

  ingress {
    from_port = 0
    to_port   = 80
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 0
    to_port   = 80
    protocol  = "udp"
    self      = true
  }

  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    self      = true
  }

  dynamic "egress" {
    for_each = local.sg_ports
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = var.tags
}

resource "aws_subnet" "privatelink" {
  count                   = length(local.pl_private_subnets_cidr)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.pl_private_subnets_cidr[count.index]
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = false // explicit private subnet

  tags = merge(var.tags, {
    Name = "${var.prefix}-pl-vpce-subnet-${var.suffix}"
  })
}

resource "aws_route_table" "pl_subnet_rt" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.prefix}-pl-spoke-route-tbl-${var.suffix}"
  })
}

resource "aws_route_table_association" "dataplane_vpce_rtb" {
  count          = length(aws_subnet.privatelink)
  subnet_id      = aws_subnet.privatelink[count.index].id
  route_table_id = aws_route_table.pl_subnet_rt.id
}

resource "aws_security_group" "privatelink-sg" {
  vpc_id = aws_vpc.this.id

  dynamic "ingress" {
    for_each = [443, # for Databricks infrastructure, cloud data sources, and library repositories
      6666,          # for private link
      2443,          # only for use with compliance security profile
    ]

    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.default_sg.id]
    }
  }

  dynamic "egress" {
    for_each = [443, # for Databricks infrastructure, cloud data sources, and library repositories
      6666,          # for private link
      2443,          # only for use with compliance security profile
    ]

    content {
      from_port       = egress.value
      to_port         = egress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.default_sg.id]
    }
  }

  tags = merge(var.tags, {
    Name = "${var.prefix}-privatelink-sg-${var.suffix}"
  })
}

resource "aws_vpc_endpoint" "backend_rest" {
  vpc_id              = aws_vpc.this.id
  service_name        = local.vpc_endpoint_backend_rest
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.privatelink-sg.id]
  subnet_ids          = aws_subnet.privatelink[*].id
  private_dns_enabled = true // try to directly set this to true in the first apply

  tags = merge(var.tags, {
    Name = "${var.prefix}-databricks-backend-rest-${var.suffix}"
  })
}

resource "aws_vpc_endpoint" "backend_relay" {
  vpc_id              = aws_vpc.this.id
  service_name        = local.vpc_endpoint_backend_relay
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.privatelink-sg.id]
  subnet_ids          = aws_subnet.privatelink[*].id
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.prefix}-databricks-backend-relay-${var.suffix}"
  })
}

resource "databricks_mws_vpc_endpoint" "backend_rest_vpce" {
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.backend_rest.id
  vpc_endpoint_name   = "${var.prefix}-vpc-spoke-backend-${var.suffix}"
  region              = var.location
}

resource "databricks_mws_vpc_endpoint" "relay_vpce" {
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.backend_relay.id
  vpc_endpoint_name   = "${var.prefix}-vpc-spoke-relay-${var.suffix}"
  region              = var.location
}

resource "databricks_mws_private_access_settings" "pla" {
  private_access_settings_name = "Private Access Settings for ${var.prefix}"
  region                       = var.location
  public_access_enabled        = true # no private link for the web ui
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = aws_vpc.this.id
  security_group_ids = [aws_security_group.default_sg.id]

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = flatten([
        aws_route_table.db_private_rt.id
      ])
      tags = {
        Name = "${var.prefix}-s3-vpc-endpoint-${var.suffix}"
      }
    },
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = aws_subnet.db_private_subnet[*].id
      tags = {
        Name = "${var.prefix}-sts-vpc-endpoint-${var.suffix}"
      }
    },
    kinesis-streams = {
      service             = "kinesis-streams"
      private_dns_enabled = true
      subnet_ids          = aws_subnet.db_private_subnet[*].id
      tags = {
        Name = "${var.prefix}-kinesis-vpc-endpoint-${var.suffix}"
      }
    },

  }

  tags = var.tags
}