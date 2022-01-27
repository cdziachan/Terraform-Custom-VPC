This template deploys the following AWS Resources using Terraform:
- a VPC
- 2 public and 2 private subnets in 2 Availability Zones
- a private route table for traffic between the private and public subnets
- a public route table for the public subnets
- an internet gateway attached to the VPC
- a web security group allowing HTTP and HTTPS access to the public subnets
- a database security group allowing ICMP/SSH/HTTP/HTTPS/MYSQL from resources in public subnets to resources in the private subnets
- a tagging system for the resources
- S3 remote state storage
