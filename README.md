This template deploys the following:
- a custom VPC
- 2 public and 2 private subnets in two Availability Zones
- a private route table for traffic between the subnets
- a public route table for the public subnet
- an internet gateway and attaches it to the VPC
- a security group allowing http and https access to the public subnets
- a security group allowing ICMP/SSH/HTTP/HTTPS/MYSQL from resources in public subnets 
  to resources in the private subnets