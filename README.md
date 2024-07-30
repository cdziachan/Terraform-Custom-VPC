
This Terraform template deploys a basic AWS VPC. Resources can be deployed into two separate Availability Zones, allowing for redundancy in the event one becomes unavailable. These can be expanded by adding additional CIDR blocks in the variables.tf file. Web facing resources can be deployed into the public subnets, while databases or other sensative resources should be placed in the private subnets. Security groups restrict access to resources in private subnets to only resources deployed in the public subnets. Below is a list of the resources the template will create.

- a VPC
- 2 public subnets
- 2 private subnets
- 2 route tables
- an internet gateway
- a web security group allowing HTTP and HTTPS access to the public subnets
- a database security group allowing ICMP/SSH/HTTP/HTTPS/MYSQL from resources in public subnets to resources in the private subnets
- a tagging system for the resources
