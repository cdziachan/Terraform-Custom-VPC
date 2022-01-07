provider "aws" {
  region = "us-west-1"
}

# Data retrieved from AWS for tagging
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}
data "aws_vpc" "prod" {
  depends_on = [aws_vpc.prod]
  tags = {
    Name = "Prod VPC"
  }
}

# Create the VPC
resource "aws_vpc" "prod" {
  cidr_block = "10.0.0.0/16"
  tags       = merge(var.tags, { Name = "Prod VPC" })
}

# Create the Public Subnets
resource "aws_subnet" "Public_Subnet_az1" {
  vpc_id                  = data.aws_vpc.prod.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name   = "Public Subnet 1"
    AZ     = "${data.aws_availability_zones.available.names[0]}"
    Region = "${data.aws_region.current.description}"
    Env    = "${var.env}"
    VPC    = "${data.aws_vpc.prod.id}"
  })
}

resource "aws_subnet" "Public_Subnet_az2" {
  vpc_id                  = data.aws_vpc.prod.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name   = "Public Subnet 2"
    AZ     = "${data.aws_availability_zones.available.names[1]}"
    Region = "${data.aws_region.current.description}"
    Env    = "${var.env}"
    VPC    = "${data.aws_vpc.prod.id}"
  })
}

# Create the Private Subnets
resource "aws_subnet" "Private_Subnet_az1" {
  vpc_id            = data.aws_vpc.prod.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(var.tags, {
    Name   = "Private Subnet 1"
    AZ     = "${data.aws_availability_zones.available.names[0]}"
    Region = "${data.aws_region.current.description}"
    Env    = "${var.env}"
    VPC    = "${data.aws_vpc.prod.id}"
  })
}


resource "aws_subnet" "Private_Subnet_az2" {
  vpc_id            = data.aws_vpc.prod.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(var.tags, {
    Name   = "Private Subnet 2"
    AZ     = "${data.aws_availability_zones.available.names[1]}"
    Region = "${data.aws_region.current.description}"
    Env    = "${var.env}"
    VPC    = "${data.aws_vpc.prod.id}"
  })
}
# Create the Internet Gateway
resource "aws_internet_gateway" "access_web" {
  vpc_id = data.aws_vpc.prod.id

  tags = merge(var.tags, {
    Name   = "Prod IGW"
    Region = "${data.aws_region.current.description}"
    Env    = "${var.env}"
    VPC    = "${data.aws_vpc.prod.id}"
  })
}

# Create the default Private Route Table
resource "aws_default_route_table" "private_rt" {
  default_route_table_id = aws_vpc.prod.default_route_table_id

  tags = merge(var.tags, {
    Name   = "Default-Private-RT"
    Region = "${data.aws_region.current.description}"
    Env    = "${var.env}"
    VPC    = "${data.aws_vpc.prod.id}"
  })
}

# Associate the Private Route Table with the Private Subnets
resource "aws_route_table_association" "private_sub_1" {
  subnet_id      = aws_subnet.Private_Subnet_az1.id
  route_table_id = aws_default_route_table.private_rt.id
}

resource "aws_route_table_association" "private_sub_2" {
  subnet_id      = aws_subnet.Private_Subnet_az2.id
  route_table_id = aws_default_route_table.private_rt.id
}

# Create the Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.access_web.id
  }

  tags = merge(var.tags, {
    Name   = "Custom-Public-RT"
    Region = "${data.aws_region.current.description}"
    Env    = "${var.env}"
    VPC    = "${data.aws_vpc.prod.id}"
  })
}

# Associate the Public Route Table with the Public Subnets
resource "aws_route_table_association" "public_sub_1" {
  subnet_id      = aws_subnet.Public_Subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_sub_2" {
  subnet_id      = aws_subnet.Public_Subnet_az2.id
  route_table_id = aws_route_table.public_rt.id
}

#Create a Security Group for the Public Subnets
resource "aws_security_group" "web_sg" {
  name        = "Web Security Group"
  description = "Security Group for the public subnet, allows web traffic ingress"
  vpc_id      = data.aws_vpc.prod.id

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      description = "allow http and https"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    description = "Allow all ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name   = "Web Security Group"
    Region = "${data.aws_region.current.description}"
    Env    = "${var.env}"
    VPC    = "${data.aws_vpc.prod.id}"
  })
}

#Create a Security Group for the Private Subnets
resource "aws_security_group" "database_sg" {
  name        = "Database Security Group"
  description = "Security Group for the private subnet, allows internal traffic ingress"
  vpc_id      = aws_vpc.prod.id

  dynamic "ingress" {
    for_each = ["80", "443", "22", "3306"]
    content {
      description = "allow http-https-ssh-mysql"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
    }
  }

  ingress {
    description = "allow ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  }

  egress {
    description = "Allow all ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, {
    Name   = "DB Security Group"
    Region = "${data.aws_region.current.description}"
    Env    = "${var.env}"
    VPC    = "${data.aws_vpc.prod.id}"
  })
}
#-------------------------------------
output "availability_zones" {
  value = data.aws_availability_zones.available[*].id
}
