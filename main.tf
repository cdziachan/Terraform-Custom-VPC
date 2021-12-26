/* This template deploys the following:
- a custom VPC
- 2 public and 2 private subnets in two Availability Zones
- a private route table for traffic between the subnets
- a public route table for the public subnet
- an internet gateway and attaches it to the VPC
- a security group allowing http and https access to the public subnets
- a security group allowing ICMP/SSH/HTTP/HTTPS/MYSQL from resources in public subnets 
  to resources in the private subnets
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
    Subnets            = "4"
  }
}

# Create the Public Subnets
resource "aws_subnet" "Public_Subnet_az1" {
  vpc_id                  = data.aws_vpc.prod.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name   = "Public Subnet 1"
    AZ     = "${data.aws_availability_zones.available.names[0]}"
    Region = "${data.aws_region.current.description}"
  }
}

resource "aws_subnet" "Public_Subnet_az2" {
  vpc_id                  = data.aws_vpc.prod.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name   = "Public Subnet 2"
    AZ     = "${data.aws_availability_zones.available.names[1]}"
    Region = "${data.aws_region.current.description}"
  }
}

# Create the Private Subnets
resource "aws_subnet" "Private_Subnet_az1" {
  vpc_id            = data.aws_vpc.prod.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name   = "Private Subnet 1"
    AZ     = "${data.aws_availability_zones.available.names[0]}"
    Region = "${data.aws_region.current.description}"
  }
}


resource "aws_subnet" "Private_Subnet_az2" {
  vpc_id            = data.aws_vpc.prod.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name   = "Private Subnet 2"
    AZ     = "${data.aws_availability_zones.available.names[1]}"
    Region = "${data.aws_region.current.description}"
  }
}
# Create the internet gateway
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

# Associate the private route table with the private subnets
resource "aws_route_table_association" "private_sub_1" {
  subnet_id      = aws_subnet.Private_Subnet_az1.id
  route_table_id = aws_default_route_table.private_rt.id
}

resource "aws_route_table_association" "private_sub_2" {
  subnet_id      = aws_subnet.Private_Subnet_az2.id
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

# Associate the public route table with the public subnets
resource "aws_route_table_association" "public_sub_1" {
  subnet_id      = aws_subnet.Public_Subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_sub_2" {
  subnet_id      = aws_subnet.Public_Subnet_az2.id
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

#Create a security group for the private subnet
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

  tags = {
    Name        = "DB Security Group"
    Environment = "Prod"
  }
}
#-------------------------------------
output "availability_zones" {
  value = data.aws_availability_zones.available.id
}
