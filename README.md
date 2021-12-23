This template deploys the following:
- a custom VPC
- a public and private subnet in two Availability Zones
- a private route table for traffic between the subnets
- a public route table for the public subnet
- an internet gateway and attaches it to the VPC
- a security group allowing http and https access to the public subnet
- a security group allowing ICMP/SSH/HTTP/HTTPS/MYSQL from resources in the public subnet to resource in the private subnet