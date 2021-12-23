/* This template deploys the following:
- a custom VPC
- a public and private subnet in two Availability Zones
- a private route table for traffic between the subnets
- a public route table for the public subnet
- an internet gateway and attaches it to the VPC
- a security group allowing http and https access to the public subnet
- a security group allowing ICMP/SSH/HTTP/HTTPS/MYSQL from resources
  in the public subnet to resource in the private subnet
*/

provider "aws" {
  region = "us-west-2"
}

# data retrieved from AWS for tagging
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}
data "aws_vpc" "prod" {
  depends_on = [aws_vpc.prod]
  tags = {
    Name = "Prod"
  }
}

# Create the VPC
resource "aws_vpc" "prod" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name               = "Prod"
    Region             = "us-west-2"
    Availability_Zones = "2"
    Subnets            = "2"
  }
}

# Create the public and private subnets
resource "aws_subnet" "Public_Subnet" {
  vpc_id                  = data.aws_vpc.prod.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name   = "Public Subnet"
    AZ     = "${data.aws_availability_zones.available.names[0]}"
    Region = "${data.aws_region.current.description}"
  }
}

resource "aws_subnet" "Private_Subnet" {
  vpc_id            = data.aws_vpc.prod.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name   = "Private Subnet"
    AZ     = "${data.aws_availability_zones.available.names[1]}"
    Region = "${data.aws_region.current.description}"
  }
}

#Create the internet gateway
resource "aws_internet_gateway" "access_web" {
  vpc_id = data.aws_vpc.prod.id

  tags = {
    Name = "Prod IGW"
    VPC  = "${data.aws_vpc.prod.id}"
  }
}

# Create the default private route table
resource "aws_default_route_table" "private_rt" {
  default_route_table_id = aws_vpc.prod.default_route_table_id

  tags = {
    Name = "Default-Private-RT"
  }
}

# Associate the private route table with the private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.Private_Subnet.id
  route_table_id = aws_default_route_table.private_rt.id
}

# Create the public route table
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.access_web.id
  }

  tags = {
    Name = "Custom-Public-RT"
    VPC  = "${data.aws_vpc.prod.id}"
  }
}

# Associate the public route table with the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.Public_Subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#Create a security group for the public subnet
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

  tags = {
    Name        = "Web Security Group"
    Environment = "Prod"
  }
}

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
      cidr_blocks = ["10.0.1.0/24"]
    }
  }

  ingress {
    description = "allow ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    description = "Allow all ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "DB Security Group"
    Environment = "Prod"
  }
}
#-------------------------------------
output "availability_zones" {
  value = data.aws_availability_zones.available.names
}
